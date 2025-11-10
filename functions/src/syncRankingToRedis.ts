/**
 * Cloud Functions - Ranking Sync to Upstash Redis
 *
 * 毎時00分にFirestoreから全ユーザーのmaxConnectionsを取得してRedisに同期
 * Redis Sorted Setを使用して高速なランキング取得を実現
 * 読み取り側は時刻ベースでキャッシュ無効化（Redisへの余計な読み取り不要）
 */

import * as functions from "firebase-functions";
import { Redis } from "@upstash/redis";

// Upstash Redis接続設定
// Firebase Functionsの環境変数から取得
const getRedisConfig = () => {
  const config = functions.config();
  return {
    url: config["upstash"]?.["redis_url"] ?? "",
    token: config["upstash"]?.["redis_token"] ?? "",
  };
};

const redis = new Redis(getRedisConfig());

const RANKING_KEY = "ranking:maxConnections";

/**
 * 共通の同期ロジック: FirestoreからRedisへ全データを同期
 * @returns 同期したユーザー数
 */
async function syncAllRankingToRedis(): Promise<number> {
  // Upstash Redis環境変数チェック
  const config = getRedisConfig();
  if (!config.url || !config.token) {
    console.warn("[Redis Sync] Skipped: Upstash Redis credentials not configured");
    throw new Error("Upstash Redis credentials not configured");
  }

  const admin = await import("firebase-admin");
  const db = admin.firestore();

  // 全ユーザーを取得（Firestore indexが不要）
  const usersSnapshot = await db
    .collection("users")
    .get();

  console.log(`[Redis Sync] Found ${usersSnapshot.size} total users`);

  // バッチでRedisに追加
  const pipeline = redis.pipeline();
  let count = 0;

  usersSnapshot.forEach((doc) => {
    const data = doc.data();
    const maxConnections = (data["maxConnections"] as number | undefined) ?? 0;

    if (maxConnections > 0) {
      pipeline.zadd(RANKING_KEY, {
        score: maxConnections,
        member: doc.id,
      });
      count++;
    }
  });

  await pipeline.exec();

  console.log(`[Redis Sync] ✅ Synced ${count} users to Redis`);
  return count;
}

/**
 * キャッシュをウォームアップ（getRanking関数を呼び出してキャッシュを事前作成）
 * 00分以降の大量リクエスト時にthundering herd problemを防ぐ
 */
async function warmupCache(): Promise<void> {
  const getRankingURL = "https://asia-northeast1-heart-beat-23158.cloudfunctions.net/getRanking";

  try {
    console.log("[Cache Warmup] Calling getRanking to warmup cache...");

    const response = await fetch(`${getRankingURL}?limit=100`);

    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }

    const data = (await response.json()) as { users?: unknown[]; cached?: boolean };
    console.log(
      `[Cache Warmup] ✅ Cache warmed up successfully (${data.users?.length || 0} users, cached: ${data.cached})`
    );
  } catch (error) {
    // キャッシュウォームアップに失敗してもエラーにしない（次回リクエスト時に取得される）
    console.error("[Cache Warmup] ⚠️ Failed to warmup cache:", error);
  }
}

/**
 * 定期実行: 毎時59分にFirestoreからRedisへ全データを同期
 * Cloud Scheduler経由で自動実行
 * 同期完了後、キャッシュをウォームアップして00分以降のリクエストに備える
 */
export const updateRankingScheduled = functions
  .region("asia-northeast1")
  .pubsub.schedule("59 * * * *") // 毎時59分（cron形式）
  .timeZone("Asia/Tokyo")
  .onRun(async () => {
    console.log("[Scheduled Ranking Sync] Starting scheduled ranking sync...");

    try {
      // Redisにランキングデータを同期
      const count = await syncAllRankingToRedis();
      console.log(`[Scheduled Ranking Sync] ✅ Successfully synced ${count} users`);

      // キャッシュをウォームアップ（00分以降のthundering herd problem対策）
      await warmupCache();

      return null;
    } catch (error) {
      console.error("[Scheduled Ranking Sync] ❌ Error:", error);
      // エラーでも次回の実行は継続
      return null;
    }
  });

/**
 * 初回セットアップ: FirestoreからRedisへ全データを同期
 * HTTPS関数として手動実行（管理者のみ）
 */
export const initialSyncRankingToRedis = functions
  .region("asia-northeast1")
  .https.onRequest(async (req, res) => {
    // セキュリティ: secretパラメータで保護
    const secret = req.query["secret"] as string;
    if (secret !== "sync-ranking-2024") {
      res.status(403).send("Forbidden");
      return;
    }

    console.log("[Manual Ranking Sync] Starting manual ranking sync...");

    try {
      const count = await syncAllRankingToRedis();
      console.log(`[Manual Ranking Sync] ✅ Successfully synced ${count} users`);

      // キャッシュをウォームアップ
      await warmupCache();

      res.status(200).send(`Successfully synced ${count} users to Redis and warmed up cache`);
    } catch (error) {
      console.error("[Manual Ranking Sync] ❌ Error:", error);
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).send(`Error: ${errorMessage}`);
    }
  });

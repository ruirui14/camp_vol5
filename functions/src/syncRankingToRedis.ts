/**
 * Cloud Functions - Ranking Sync to Upstash Redis
 *
 * Firestoreのmax Connections更新時に、Upstash Redisにランキングデータを同期
 * Redis Sorted Setを使用して高速なランキング取得を実現
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
 * Firestoreのusers/{userId}ドキュメント更新時にRedisへ同期
 * maxConnectionsフィールドが更新された場合のみ実行
 */
export const syncRankingToRedis = functions
  .region("asia-northeast1")
  .firestore.document("users/{userId}")
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // maxConnectionsが変更された場合のみ処理
    const beforeMaxConnections = (beforeData["maxConnections"] as number | undefined) ?? 0;
    const afterMaxConnections = (afterData["maxConnections"] as number | undefined) ?? 0;

    if (beforeMaxConnections === afterMaxConnections) {
      console.log(`[Redis Sync] Skipped: maxConnections not changed for user ${userId}`);
      return null;
    }

    try {
      // Upstash Redis環境変数が設定されていない場合はスキップ
      const config = getRedisConfig();
      if (!config.url || !config.token) {
        console.warn("[Redis Sync] Skipped: Upstash Redis credentials not configured");
        return null;
      }

      // Redis Sorted Setに追加/更新
      // score = maxConnections, member = userId
      await redis.zadd(RANKING_KEY, {
        score: afterMaxConnections,
        member: userId,
      });

      console.log(
        `[Redis Sync] ✅ Updated ranking for user ${userId}: ${beforeMaxConnections} → ${afterMaxConnections}`
      );

      return null;
    } catch (error) {
      // Redisエラーでも処理を続行（Firestoreがプライマリ）
      console.error(`[Redis Sync] ❌ Failed to sync to Redis for user ${userId}:`, error);
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

    try {
      // Upstash Redis環境変数チェック
      const config = getRedisConfig();
      if (!config.url || !config.token) {
        res.status(500).send("Upstash Redis credentials not configured");
        return;
      }

      const admin = await import("firebase-admin");
      const db = admin.firestore();

      // 全ユーザーを取得（Firestore indexが不要）
      const usersSnapshot = await db
        .collection("users")
        .get();

      console.log(`[Redis Initial Sync] Found ${usersSnapshot.size} total users`);

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

      console.log(`[Redis Initial Sync] ✅ Synced ${count} users to Redis`);
      res.status(200).send(`Successfully synced ${count} users to Redis`);
    } catch (error) {
      console.error("[Redis Initial Sync] ❌ Error:", error);
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).send(`Error: ${errorMessage}`);
    }
  });

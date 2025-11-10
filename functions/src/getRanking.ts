/**
 * Cloud Functions - Get Ranking with Cache
 *
 * ランキングデータをオンメモリキャッシュ付きで取得
 * Upstash Redisへの読み取り回数を削減
 * ランキングは毎時59分に更新されるため、時が変わったらキャッシュを無効化
 */

import * as functions from "firebase-functions";
import { Redis } from "@upstash/redis";

// Upstash Redis接続設定
const getRedisConfig = () => {
  const config = functions.config();
  return {
    url: (config["upstash"]?.["redis_url"] as string) ?? "",
    token: (config["upstash"]?.["redis_token"] as string) ?? "",
  };
};

const redis = new Redis(getRedisConfig());

const RANKING_KEY = "ranking:maxConnections";

// オンメモリキャッシュ（グローバル変数）
interface RankingCache {
  data: RankingUser[];
  timestamp: number;
}

interface RankingUser {
  id: string;
  name: string;
  maxConnections: number;
  maxConnectionsUpdatedAt?: number; // Unix timestamp (ms)
}

let rankingCache: RankingCache | null = null;

/**
 * RedisからユーザーIDリストを取得
 */
async function fetchUserIdsFromRedis(limit: number): Promise<string[]> {
  const config = getRedisConfig();
  if (!config.url || !config.token) {
    throw new Error("Upstash Redis credentials not configured");
  }

  // Redis Sorted Setから取得（降順）
  const userIds = await redis.zrange(RANKING_KEY, 0, limit - 1, { rev: true });
  return userIds as string[];
}

/**
 * FirestoreからUserデータを取得
 */
async function fetchUsersFromFirestore(userIds: string[]): Promise<RankingUser[]> {
  const admin = await import("firebase-admin");
  const db = admin.firestore();

  const users: RankingUser[] = [];

  // バッチで取得（最大100件）
  for (let i = 0; i < userIds.length; i += 100) {
    const batch = userIds.slice(i, i + 100);
    const promises = batch.map(async (userId): Promise<RankingUser | null> => {
      const doc = await db.collection("users").doc(userId).get();
      if (!doc.exists) return null;

      const data = doc.data();
      if (!data) return null;

      const rankingUser: RankingUser = {
        id: userId,
        name: data["name"] as string,
        maxConnections: (data["maxConnections"] as number) ?? 0,
        maxConnectionsUpdatedAt: data["maxConnectionsUpdatedAt"]?.toMillis() as number | undefined,
      };

      return rankingUser;
    });

    const results = await Promise.all(promises);
    const validResults = results.filter((u): u is RankingUser => u !== null);
    users.push(...validResults);
  }

  // Redis Sorted Setの順序を保持
  const userMap = new Map(users.map((u) => [u.id, u]));
  const orderedUsers = userIds.map((id) => userMap.get(id)).filter((u): u is RankingUser => u !== undefined);
  return orderedUsers;
}

/**
 * ランキング取得（キャッシュ付き）
 * HTTPS関数として外部から呼び出し可能
 */
export const getRanking = functions
  .region("asia-northeast1")
  .https.onRequest(async (req, res) => {
    // CORS設定
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "GET") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      const limit = parseInt(req.query["limit"] as string) || 100;

      // キャッシュチェック（時刻ベース）
      if (rankingCache) {
        const cacheDate = new Date(rankingCache.timestamp);
        const currentDate = new Date();
        const cacheHour = cacheDate.getHours();
        const currentHour = currentDate.getHours();

        // 時が変わっていたらキャッシュを無効化（毎時59分に更新されるため）
        if (cacheHour !== currentHour) {
          console.log(
            `[getRanking] 🔄 Cache invalidated: hour changed (cache: ${cacheHour}:xx, current: ${currentHour}:xx)`
          );
          rankingCache = null; // キャッシュを無効化
        } else {
          // 同じ時間内ならキャッシュヒット
          const elapsed = Date.now() - rankingCache.timestamp;
          console.log(`[getRanking] ✅ Cache hit (age: ${Math.floor(elapsed / 1000)}s, hour: ${currentHour})`);
          const result = rankingCache.data.slice(0, limit);
          res.status(200).json({
            users: result,
            cached: true,
            cacheAge: Math.floor(elapsed / 1000),
          });
          return;
        }
      }

      // キャッシュミス: Redisから取得
      console.log(`[getRanking] 🔍 Fetching from Redis (limit: ${limit})`);
      const userIds = await fetchUserIdsFromRedis(limit);
      console.log(`[getRanking] Found ${userIds.length} user IDs from Redis`);

      // Firestoreからユーザー詳細を取得
      const users = await fetchUsersFromFirestore(userIds);
      console.log(`[getRanking] Fetched ${users.length} users from Firestore`);

      // キャッシュ更新
      rankingCache = {
        data: users,
        timestamp: Date.now(),
      };

      res.status(200).json({
        users: users.slice(0, limit),
        cached: false,
        cacheAge: 0,
      });
    } catch (error) {
      console.error("[getRanking] ❌ Error:", error);
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({ error: errorMessage });
    }
  });

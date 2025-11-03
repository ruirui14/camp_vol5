/**
 * Cloud Functions - Ranking Sync to Upstash Redis
 *
 * Firestoreのmax Connections更新時に、Upstash Redisにランキングデータを同期
 * Redis Sorted Setを使用して高速なランキング取得を実現
 */
import * as functions from "firebase-functions";
/**
 * Firestoreのusers/{userId}ドキュメント更新時にRedisへ同期
 * maxConnectionsフィールドが更新された場合のみ実行
 */
export declare const syncRankingToRedis: functions.CloudFunction<functions.Change<functions.firestore.QueryDocumentSnapshot>>;
/**
 * 初回セットアップ: FirestoreからRedisへ全データを同期
 * HTTPS関数として手動実行（管理者のみ）
 */
export declare const initialSyncRankingToRedis: functions.HttpsFunction;
//# sourceMappingURL=syncRankingToRedis.d.ts.map
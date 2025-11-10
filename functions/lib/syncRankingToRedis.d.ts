/**
 * Cloud Functions - Ranking Sync to Upstash Redis
 *
 * 1時間に1回、Firestoreから全ユーザーのmaxConnectionsを取得してRedisに同期
 * Redis Sorted Setを使用して高速なランキング取得を実現
 */
import * as functions from "firebase-functions";
/**
 * 定期実行: 1時間に1回、FirestoreからRedisへ全データを同期
 * Cloud Scheduler経由で自動実行
 */
export declare const updateRankingScheduled: functions.CloudFunction<unknown>;
/**
 * 初回セットアップ: FirestoreからRedisへ全データを同期
 * HTTPS関数として手動実行（管理者のみ）
 */
export declare const initialSyncRankingToRedis: functions.HttpsFunction;
//# sourceMappingURL=syncRankingToRedis.d.ts.map
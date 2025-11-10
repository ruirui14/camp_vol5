/**
 * Cloud Functions - Ranking Sync to Upstash Redis
 *
 * 毎時00分にFirestoreから全ユーザーのmaxConnectionsを取得してRedisに同期
 * Redis Sorted Setを使用して高速なランキング取得を実現
 * 読み取り側は時刻ベースでキャッシュ無効化（Redisへの余計な読み取り不要）
 */
import * as functions from "firebase-functions";
/**
 * 定期実行: 毎時59分にFirestoreからRedisへ全データを同期
 * Cloud Scheduler経由で自動実行
 * 同期完了後、キャッシュをウォームアップして00分以降のリクエストに備える
 */
export declare const updateRankingScheduled: functions.CloudFunction<unknown>;
/**
 * 初回セットアップ: FirestoreからRedisへ全データを同期
 * HTTPS関数として手動実行（管理者のみ）
 */
export declare const initialSyncRankingToRedis: functions.HttpsFunction;
//# sourceMappingURL=syncRankingToRedis.d.ts.map
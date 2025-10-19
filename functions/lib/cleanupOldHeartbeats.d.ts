/**
 * Cloud Functions for Firebase - 古いハートビートデータの自動削除
 *
 * 毎日定時に実行され、1時間より古いハートビートデータを削除する
 * - Realtime Database の live_heartbeats から古いデータを削除
 * - notification_triggers から古いトリガーも削除
 */
/**
 * 毎日午前3時（JST）に実行される定期処理
 * 1時間より古いハートビートデータを削除
 *
 * スケジュール: 毎日 18:00 UTC (= 03:00 JST)
 * タイムゾーン: Asia/Tokyo
 */
export declare const cleanupOldHeartbeats: import("firebase-functions/v2/scheduler").ScheduleFunction;
//# sourceMappingURL=cleanupOldHeartbeats.d.ts.map
/**
 * Cloud Functions for Firebase - Notification Trigger Handler
 *
 * notification_triggers/{userId} への書き込みを監視して、フォロワーにプッシュ通知を送信する
 *
 * iOS側で以下をチェック済み：
 * - BPM変化検知
 * - 1時間経過チェック（レート制限）
 *
 * この関数の処理：
 * 1. トリガーを検知
 * 2. live_heartbeats から最新のBPMを取得
 * 3. 通知送信
 * 4. クリーンアップ
 */
/**
 * 通知トリガー時のCloud Function
 * notification_triggers/{userId} への書き込みを監視
 */
export declare const onNotificationTrigger: import("firebase-functions/v2").CloudFunction<import("firebase-functions/v2/database").DatabaseEvent<import("firebase-functions/v2").Change<import("firebase-functions/v2/database").DataSnapshot>, {
    userId: string;
}>>;
//# sourceMappingURL=notificationTrigger.d.ts.map
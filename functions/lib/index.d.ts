/**
 * Cloud Functions for Firebase - Heartbeat Notification System (TypeScript)
 *
 * BPMの書き込みを監視して、フォロワーにプッシュ通知を送信する
 * レート制限により、過剰な通知を防ぐ
 *
 * モダンなTypeScriptで実装:
 * - 厳格な型チェック
 * - async/awaitによる非同期処理
 * - オプショナルチェイニングとNull合体演算子
 * - 関数型プログラミングのアプローチ
 */
export { cleanupOldHeartbeats } from "./cleanupOldHeartbeats";
/**
 * 通知トリガー時のCloud Function
 * notification_triggers/{userId} への書き込みを監視
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
export declare const onNotificationTrigger: import("firebase-functions/v2").CloudFunction<import("firebase-functions/v2/database").DatabaseEvent<import("firebase-functions/v2").Change<import("firebase-functions/v2/database").DataSnapshot>, {
    userId: string;
}>>;
//# sourceMappingURL=index.d.ts.map
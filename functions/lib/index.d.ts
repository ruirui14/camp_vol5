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
/**
 * BPM書き込み時のトリガー関数
 * live_heartbeats/{userId} への書き込みを監視
 */
export declare const onHeartbeatUpdate: import("firebase-functions/v2").CloudFunction<import("firebase-functions/v2/database").DatabaseEvent<import("firebase-functions/v2").Change<import("firebase-functions/v2/database").DataSnapshot>, {
    userId: string;
}>>;
//# sourceMappingURL=index.d.ts.map
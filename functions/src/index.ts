/**
 * Cloud Functions for Firebase - Heartbeat Notification System (TypeScript)
 *
 * エントリーポイント
 * すべてのCloud Functionsをここからエクスポート
 *
 * モダンなTypeScriptで実装:
 * - 厳格な型チェック
 * - async/awaitによる非同期処理
 * - オプショナルチェイニングとNull合体演算子
 * - 関数型プログラミングのアプローチ
 */

import * as admin from "firebase-admin";

// Firebase初期化（一度だけ）
admin.initializeApp();

// 各Cloud Functionをエクスポート
export { onNotificationTrigger } from "./notificationTrigger";
export { cleanupOldHeartbeats } from "./cleanupOldHeartbeats";
export { updateRankingScheduled, initialSyncRankingToRedis } from "./syncRankingToRedis";

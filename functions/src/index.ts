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

import { onValueWritten } from "firebase-functions/v2/database";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";
// import { Redis } from "@upstash/redis"; // ★ 不要（iOS側でレート制限管理）
import type {
  HeartbeatData,
  NotificationTriggerData,
  FollowerData,
  UserData,
  NotificationPayload,
  FunctionResult,
  NotificationResult,
} from "./types";

// Firebase初期化
admin.initializeApp();

// 古いハートビートデータの自動削除機能をエクスポート
export { cleanupOldHeartbeats } from "./cleanupOldHeartbeats";

const db = admin.firestore();

// 定数定義
const REGION = "asia-southeast1" as const;

// ★ Upstash Redisは不要（iOS側でレート制限管理）
// const redis = new Redis({
//   url: process.env["UPSTASH_REDIS_REST_URL"] || "",
//   token: process.env["UPSTASH_REDIS_REST_TOKEN"] || "",
// });
// const NOTIFICATION_COOLDOWN_SECONDS = 3600;

/**
 * 型ガード: FCMトークン配列が空でないことを確認
 */
function isNonEmptyArray<T>(arr: T[]): arr is [T, ...T[]] {
  return arr.length > 0;
}

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
export const onNotificationTrigger = onValueWritten(
  {
    ref: "/notification_triggers/{userId}",
    region: REGION,
  },
  async (event): Promise<FunctionResult> => {
    const { userId } = event.params;
    const afterSnapshot = event.data.after;

    // データが削除された場合は処理をスキップ
    if (!afterSnapshot.exists()) {
      logger.info(`Notification trigger deleted for user: ${userId}`);
      return null;
    }

    const triggerData = afterSnapshot.val() as NotificationTriggerData;
    logger.info(`Notification trigger received for user ${userId} at ${triggerData.t}`);

    try {
      // live_heartbeatsから最新のBPMを取得
      const heartbeatSnapshot = await admin
        .database()
        .ref(`live_heartbeats/${userId}`)
        .once("value");

      if (!heartbeatSnapshot.exists()) {
        logger.warn(`No heartbeat data found for user: ${userId}`);
        await afterSnapshot.ref.remove();
        return null;
      }

      const heartbeatData = heartbeatSnapshot.val() as HeartbeatData;
      const { bpm } = heartbeatData;

      logger.info(`Retrieved heartbeat data for user ${userId}: ${bpm} bpm`);

      // フォロワーを取得
      const followers = await getFollowers(userId);
      if (followers.length === 0) {
        logger.info(`No followers found for user: ${userId}`);
        await afterSnapshot.ref.remove();
        return null;
      }

      // ユーザー情報を取得
      const user = await getUser(userId);
      if (!user) {
        logger.warn(`User not found: ${userId}`);
        await afterSnapshot.ref.remove();
        return null;
      }

      // 通知送信対象のトークンを収集
      const tokens = followers
        .filter(
          (follower): follower is FollowerData & { fcmToken: string } =>
            follower.notificationEnabled && typeof follower.fcmToken === "string"
        )
        .map((follower) => follower.fcmToken);

      if (!isNonEmptyArray(tokens)) {
        logger.info(`No valid FCM tokens found for user: ${userId}`);
        await afterSnapshot.ref.remove();
        return null;
      }

      // プッシュ通知を送信
      await sendNotifications(tokens, user.name, bpm);

      logger.info(`Successfully sent ${tokens.length} notifications for user: ${userId}`);

      // 処理完了後、トリガーデータを削除（クリーンアップ）
      await afterSnapshot.ref.remove();
      logger.info(`Cleaned up notification trigger for user: ${userId}`);

      return null;
    } catch (error) {
      logger.error(`Error processing notification trigger for user ${userId}:`, error);
      // エラー時もクリーンアップを試みる
      try {
        await afterSnapshot.ref.remove();
      } catch (cleanupError) {
        logger.error(`Failed to cleanup trigger for user ${userId}:`, cleanupError);
      }
      return null;
    }
  }
);

// ★ iOS側でレート制限管理するため、この関数は不要
// /**
//  * 通知のレート制限をチェック（Redis版）
//  */
// async function checkNotificationCooldown(userId: string): Promise<boolean> {
//   try {
//     const key = `notification_cooldown:${userId}`;
//     const exists = await redis.exists(key);
//     return exists === 0;
//   } catch (error) {
//     logger.error(`Redis error in checkNotificationCooldown for user ${userId}:`, error);
//     return false;
//   }
// }

/**
 * フォロワー一覧を取得
 * @param userId - ユーザーID
 * @returns フォロワー配列
 */
async function getFollowers(userId: string): Promise<FollowerData[]> {
  const snapshot = await db.collection("users").doc(userId).collection("followers").get();

  return snapshot.docs.map((doc) => ({
    followerId: doc.id,
    ...(doc.data() as Omit<FollowerData, "followerId">),
  }));
}

/**
 * ユーザー情報を取得
 * @param userId - ユーザーID
 * @returns ユーザー情報（存在しない場合はnull）
 */
async function getUser(userId: string): Promise<UserData | null> {
  const doc = await db.collection("users").doc(userId).get();

  if (!doc.exists) {
    return null;
  }

  return {
    id: doc.id,
    ...(doc.data() as Omit<UserData, "id">),
  };
}

/**
 * プッシュ通知を送信
 * @param tokens - FCMトークン配列（空でないことが保証されている）
 * @param userName - ユーザー名
 * @param bpm - 心拍数
 */
async function sendNotifications(
  tokens: readonly [string, ...string[]],
  userName: string,
  bpm: number
): Promise<void> {
  const message: NotificationPayload = {
    notification: {
      title: `${userName}さんの心拍数が更新されました`,
      body: `現在の心拍数: ${bpm} bpm`,
    },
    data: {
      type: "heartbeat_update",
      bpm: String(bpm),
    },
    tokens: [...tokens], // readonlyを解除
  };

  const response = (await admin.messaging().sendEachForMulticast(message)) as NotificationResult;

  logger.info(
    `Notification sent: ${response.successCount} success, ${response.failureCount} failure`
  );

  // 失敗したトークンの処理
  if (response.failureCount > 0) {
    response.responses.forEach((resp, idx) => {
      if (!resp.success && resp.error) {
        logger.error(`Failed to send to token ${tokens[idx]}:`, resp.error);
      }
    });
  }
}

// ★ iOS側でレート制限管理するため、この関数は不要
// /**
//  * 最終通知送信時刻を更新（Redis版）
//  */
// async function updateLastNotificationSent(userId: string): Promise<void> {
//   try {
//     const key = `notification_cooldown:${userId}`;
//     const now = Date.now();
//     await redis.setex(key, NOTIFICATION_COOLDOWN_SECONDS, now.toString());
//     logger.info(`Notification cooldown set for user ${userId}: ${NOTIFICATION_COOLDOWN_SECONDS}s (1 hour)`);
//   } catch (error) {
//     logger.error(`Redis error in updateLastNotificationSent for user ${userId}:`, error);
//   }
// }

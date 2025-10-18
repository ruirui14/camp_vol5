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
import type {
  HeartbeatData,
  FollowerData,
  UserData,
  NotificationPayload,
  FunctionResult,
  NotificationResult,
} from "./types";

// Firebase初期化
admin.initializeApp();

const db = admin.firestore();
const rtdb = admin.database();

// 定数定義
const NOTIFICATION_COOLDOWN_MS = 300000; // 5分 (5 * 60 * 1000)
const REGION = "asia-southeast1" as const;

/**
 * 型ガード: FCMトークン配列が空でないことを確認
 */
function isNonEmptyArray<T>(arr: T[]): arr is [T, ...T[]] {
  return arr.length > 0;
}

/**
 * BPM書き込み時のトリガー関数
 * live_heartbeats/{userId} への書き込みを監視
 */
export const onHeartbeatUpdate = onValueWritten(
  {
    ref: "/live_heartbeats/{userId}",
    region: REGION,
  },
  async (event): Promise<FunctionResult> => {
    const { userId } = event.params;
    const beforeSnapshot = event.data.before;
    const afterSnapshot = event.data.after;

    // データが削除された場合は処理をスキップ
    if (!afterSnapshot.exists()) {
      logger.info(`Heartbeat deleted for user: ${userId}`);
      return null;
    }

    const beforeData = beforeSnapshot.val() as HeartbeatData | null;
    const afterData = afterSnapshot.val() as HeartbeatData;
    const { bpm } = afterData;

    // BPMが変更されていない場合はスキップ（connectionsの変更などを無視）
    if (beforeData?.bpm === afterData.bpm) {
      logger.info(
        `BPM unchanged for user ${userId} (connections or other field changed), skipping notification`
      );
      return null;
    }

    logger.info(`BPM update detected for user ${userId}: ${bpm} bpm`);

    try {
      // レート制限チェック
      const canSendNotification = await checkNotificationCooldown(userId);
      if (!canSendNotification) {
        logger.info(`Notification cooldown active for user: ${userId}`);
        return null;
      }

      // フォロワーを取得
      const followers = await getFollowers(userId);
      if (followers.length === 0) {
        logger.info(`No followers found for user: ${userId}`);
        return null;
      }

      // ユーザー情報を取得
      const user = await getUser(userId);
      if (!user) {
        logger.warn(`User not found: ${userId}`);
        return null;
      }

      // 通知送信対象のトークンを収集（filterでnullish値を除外）
      const tokens = followers
        .filter(
          (follower): follower is FollowerData & { fcmToken: string } =>
            follower.notificationEnabled && typeof follower.fcmToken === "string"
        )
        .map((follower) => follower.fcmToken);

      if (!isNonEmptyArray(tokens)) {
        logger.info(`No valid FCM tokens found for user: ${userId}`);
        return null;
      }

      // プッシュ通知を送信
      await sendNotifications(tokens, user.name, bpm);

      // 最終通知送信時刻を更新
      await updateLastNotificationSent(userId);

      logger.info(`Successfully sent ${tokens.length} notifications for user: ${userId}`);
      return null;
    } catch (error) {
      logger.error(`Error processing heartbeat for user ${userId}:`, error);
      return null;
    }
  }
);

/**
 * 通知のレート制限をチェック
 * @param userId - ユーザーID
 * @returns 通知を送信可能か
 */
async function checkNotificationCooldown(userId: string): Promise<boolean> {
  const ref = rtdb.ref(`live_heartbeats/${userId}/lastNotificationSent`);
  const snapshot = await ref.once("value");
  const lastSent = snapshot.val() as number | null;

  // 初回送信の場合はtrue
  if (!lastSent) {
    return true;
  }

  const now = Date.now();
  const timeSinceLastSent = now - lastSent;

  return timeSinceLastSent >= NOTIFICATION_COOLDOWN_MS;
}

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

/**
 * 最終通知送信時刻を更新
 * @param userId - ユーザーID
 */
async function updateLastNotificationSent(userId: string): Promise<void> {
  const ref = rtdb.ref(`live_heartbeats/${userId}/lastNotificationSent`);
  await ref.set(Date.now());
}

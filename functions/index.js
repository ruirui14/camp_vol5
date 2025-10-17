/**
 * Cloud Functions for Firebase - Heartbeat Notification System
 *
 * BPMの書き込みを監視して、フォロワーにプッシュ通知を送信する
 * レート制限により、過剰な通知を防ぐ
 */

const { onValueWritten } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const rtdb = admin.database();

// 通知の送信間隔（ミリ秒）- デフォルト: 5分
const NOTIFICATION_COOLDOWN_MS = 5 * 60 * 1000;

/**
 * BPM書き込み時のトリガー関数
 * live_heartbeats/{userId} への書き込みを監視
 */
exports.onHeartbeatUpdate = onValueWritten(
  {
    ref: "/live_heartbeats/{userId}",
    region: "asia-southeast1", // シンガポールリージョン（東京はEventarc未対応）
  },
  async (event) => {
    const userId = event.params.userId;
    const beforeSnapshot = event.data.before;
    const afterSnapshot = event.data.after;

    // データが削除された場合は何もしない
    if (!afterSnapshot.exists()) {
      console.log(`Heartbeat deleted for user: ${userId}`);
      return null;
    }

    const beforeData = beforeSnapshot.val();
    const afterData = afterSnapshot.val();
    const bpm = afterData.bpm;
    const timestamp = afterData.timestamp;

    // bpmが変更されていない場合は何もしない（connectionsの変更などを無視）
    if (beforeData && beforeData.bpm === afterData.bpm) {
      console.log(
        `BPM unchanged for user ${userId} (connections or other field changed), skipping notification`
      );
      return null;
    }

    console.log(`BPM update detected for user ${userId}: ${bpm} bpm`);

    try {
      // 1. レート制限チェック
      const canSendNotification = await checkNotificationCooldown(userId);
      if (!canSendNotification) {
        console.log(`Notification cooldown active for user: ${userId}`);
        return null;
      }

      // 2. フォロワーを取得
      const followers = await getFollowers(userId);
      if (followers.length === 0) {
        console.log(`No followers found for user: ${userId}`);
        return null;
      }

      // 3. フォロワーのユーザー情報を取得
      const followerUser = await getUser(userId);
      if (!followerUser) {
        console.log(`User not found: ${userId}`);
        return null;
      }

      // 4. 通知送信対象のトークンを収集
      const tokens = followers
        .filter((follower) => follower.notificationEnabled && follower.fcmToken)
        .map((follower) => follower.fcmToken);

      if (tokens.length === 0) {
        console.log(`No valid FCM tokens found for user: ${userId}`);
        return null;
      }

      // 5. プッシュ通知を送信
      await sendNotifications(tokens, followerUser.name, bpm);

      // 6. 最終通知送信時刻を更新
      await updateLastNotificationSent(userId);

      console.log(
        `Successfully sent ${tokens.length} notifications for user: ${userId}`
      );
      return null;
    } catch (error) {
      console.error(`Error processing heartbeat for user ${userId}:`, error);
      return null;
    }
  }
);

/**
 * 通知のレート制限をチェック
 * @param {string} userId - ユーザーID
 * @returns {Promise<boolean>} - 通知を送信可能か
 */
async function checkNotificationCooldown(userId) {
  const ref = rtdb.ref(`live_heartbeats/${userId}/lastNotificationSent`);
  const snapshot = await ref.once("value");
  const lastSent = snapshot.val();

  if (!lastSent) {
    return true; // 初回送信
  }

  const now = Date.now();
  const timeSinceLastSent = now - lastSent;

  return timeSinceLastSent >= NOTIFICATION_COOLDOWN_MS;
}

/**
 * フォロワー一覧を取得
 * @param {string} userId - ユーザーID
 * @returns {Promise<Array>} - フォロワー配列
 */
async function getFollowers(userId) {
  const snapshot = await db
    .collection("users")
    .doc(userId)
    .collection("followers")
    .get();

  return snapshot.docs.map((doc) => ({
    followerId: doc.id,
    ...doc.data(),
  }));
}

/**
 * ユーザー情報を取得
 * @param {string} userId - ユーザーID
 * @returns {Promise<Object|null>} - ユーザー情報
 */
async function getUser(userId) {
  const doc = await db.collection("users").doc(userId).get();
  if (!doc.exists) {
    return null;
  }
  return { id: doc.id, ...doc.data() };
}

/**
 * プッシュ通知を送信
 * @param {string[]} tokens - FCMトークン配列
 * @param {string} userName - ユーザー名
 * @param {number} bpm - 心拍数
 */
async function sendNotifications(tokens, userName, bpm) {
  const message = {
    notification: {
      title: `${userName}さんの心拍数が更新されました`,
      body: `現在の心拍数: ${bpm} bpm`,
    },
    data: {
      type: "heartbeat_update",
      bpm: String(bpm),
    },
    tokens: tokens,
  };

  const response = await admin.messaging().sendEachForMulticast(message);
  console.log(
    `Notification sent: ${response.successCount} success, ${response.failureCount} failure`
  );

  // 失敗したトークンの処理
  if (response.failureCount > 0) {
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        console.error(`Failed to send to token ${tokens[idx]}:`, resp.error);
      }
    });
  }
}

/**
 * 最終通知送信時刻を更新
 * @param {string} userId - ユーザーID
 */
async function updateLastNotificationSent(userId) {
  const ref = rtdb.ref(`live_heartbeats/${userId}/lastNotificationSent`);
  await ref.set(Date.now());
}

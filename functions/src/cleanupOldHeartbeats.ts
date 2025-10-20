/**
 * Cloud Functions for Firebase - 古いハートビートデータの自動削除
 *
 * 毎日定時に実行され、1時間より古いハートビートデータを削除する
 * - Realtime Database の live_heartbeats から古いデータを削除
 * - notification_triggers から古いトリガーも削除
 */

import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";

// 定数定義
const REGION = "asia-southeast1" as const;
const ONE_HOUR_MS = 60 * 60 * 1000; // 1時間（ミリ秒）

interface HeartbeatData {
  bpm: number;
  timestamp: number;
}

interface NotificationTriggerData {
  t: number; // timestamp
}

/**
 * 毎日午前3時（JST）に実行される定期処理
 * 1時間より古いハートビートデータを削除
 *
 * スケジュール: 毎日 18:00 UTC (= 03:00 JST)
 * タイムゾーン: Asia/Tokyo
 */
export const cleanupOldHeartbeats = onSchedule(
  {
    schedule: "0 18 * * *", // 毎日18:00 UTC (JST 03:00)
    timeZone: "Asia/Tokyo",
    region: REGION,
  },
  async () => {
    logger.info("Starting cleanup of old heartbeat data");

    const now = Date.now();
    const cutoffTime = now - ONE_HOUR_MS;

    let deletedHeartbeatsCount = 0;
    let deletedTriggersCount = 0;

    try {
      // live_heartbeats から古いデータを削除
      const heartbeatsRef = admin.database().ref("live_heartbeats");
      const heartbeatsSnapshot = await heartbeatsRef.once("value");

      if (heartbeatsSnapshot.exists()) {
        const updates: Record<string, null> = {};

        heartbeatsSnapshot.forEach((userSnapshot) => {
          const userId = userSnapshot.key;
          const data = userSnapshot.val() as HeartbeatData;

          if (data.timestamp < cutoffTime) {
            updates[`${userId}`] = null; // 削除マーク
            deletedHeartbeatsCount++;
            logger.info(
              `Marking heartbeat for deletion: user=${userId}, timestamp=${data.timestamp}, age=${Math.round((now - data.timestamp) / 1000 / 60)} minutes`
            );
          }
        });

        if (Object.keys(updates).length > 0) {
          await heartbeatsRef.update(updates);
          logger.info(`Deleted ${deletedHeartbeatsCount} old heartbeat records`);
        }
      }

      // notification_triggers から古いデータを削除
      const triggersRef = admin.database().ref("notification_triggers");
      const triggersSnapshot = await triggersRef.once("value");

      if (triggersSnapshot.exists()) {
        const updates: Record<string, null> = {};

        triggersSnapshot.forEach((userSnapshot) => {
          const userId = userSnapshot.key;
          const data = userSnapshot.val() as NotificationTriggerData;

          if (data.t < cutoffTime) {
            updates[`${userId}`] = null; // 削除マーク
            deletedTriggersCount++;
            logger.info(
              `Marking notification trigger for deletion: user=${userId}, timestamp=${data.t}, age=${Math.round((now - data.t) / 1000 / 60)} minutes`
            );
          }
        });

        if (Object.keys(updates).length > 0) {
          await triggersRef.update(updates);
          logger.info(`Deleted ${deletedTriggersCount} old notification trigger records`);
        }
      }

      logger.info(
        `Cleanup completed: ${deletedHeartbeatsCount} heartbeats, ${deletedTriggersCount} triggers deleted`
      );
    } catch (error) {
      logger.error("Error during cleanup:", error);
      throw error; // Cloud Functionsのリトライ機構を活用
    }
  }
);

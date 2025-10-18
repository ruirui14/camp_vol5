/**
 * 型定義ファイル
 * Firebase Functionsで使用するデータ型を定義
 */

/**
 * Realtime Databaseのheartbeatデータ型
 */
export interface HeartbeatData {
  bpm: number;
  timestamp: number;
  lastNotificationSent?: number;
}

/**
 * Firestoreのフォロワー情報型
 */
export interface FollowerData {
  followerId: string;
  fcmToken?: string;
  notificationEnabled: boolean;
  createdAt: FirebaseFirestore.Timestamp;
}

/**
 * Firestoreのユーザー情報型
 */
export interface UserData {
  id: string;
  name: string;
  inviteCode: string;
  allowQRRegistration: boolean;
}

/**
 * プッシュ通知のペイロード型
 */
export interface NotificationPayload {
  notification: {
    title: string;
    body: string;
  };
  data: {
    type: "heartbeat_update";
    bpm: string;
  };
  tokens: string[];
}

/**
 * 関数の戻り値型（null or undefined）
 */
export type FunctionResult = null | undefined | void;

/**
 * FCMトークンの配列（空でない）
 */
export type FCMTokens = readonly [string, ...string[]];

/**
 * 通知送信結果の型
 */
export interface NotificationResult {
  successCount: number;
  failureCount: number;
  responses: Array<{
    success: boolean;
    error?: Error;
  }>;
}

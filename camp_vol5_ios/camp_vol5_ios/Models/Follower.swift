// Models/Follower.swift
// フォロワー情報を表す純粋なデータモデル
// FCMトークンと通知設定を含む

import Foundation

/// フォロワー情報を表すドメインモデル
/// users/{userId}/followers/{followerId} に保存
struct Follower: Codable, Identifiable, Equatable {
    let id: String  // followerId
    let followerId: String
    let fcmToken: String?  // プッシュ通知用トークン（キャッシュ）
    let notificationEnabled: Bool  // フォローしている人毎の通知設定
    let createdAt: Date?

    // MARK: - Initialization

    /// 標準イニシャライザ
    init(
        id: String,
        followerId: String,
        fcmToken: String?,
        notificationEnabled: Bool,
        createdAt: Date?
    ) {
        self.id = id
        self.followerId = followerId
        self.fcmToken = fcmToken
        self.notificationEnabled = notificationEnabled
        self.createdAt = createdAt
    }

    // MARK: - Convenience Initializers

    /// 新規フォロワー作成用のコンビニエンスイニシャライザ
    init(followerId: String, fcmToken: String?) {
        self.init(
            id: followerId,
            followerId: followerId,
            fcmToken: fcmToken,
            notificationEnabled: true,  // デフォルトで通知ON
            createdAt: Date()
        )
    }
}

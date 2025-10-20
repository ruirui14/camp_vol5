// Models/Following.swift
// フォロー先情報を表す純粋なデータモデル

import Foundation

/// フォロー先情報を表すドメインモデル
/// users/{userId}/following/{followingId} に保存
struct Following: Codable, Identifiable, Equatable {
    let id: String  // followingId
    let followingId: String
    let createdAt: Date?

    // MARK: - Initialization

    /// 標準イニシャライザ
    init(
        id: String,
        followingId: String,
        createdAt: Date?
    ) {
        self.id = id
        self.followingId = followingId
        self.createdAt = createdAt
    }

    // MARK: - Convenience Initializers

    /// 新規フォロー作成用のコンビニエンスイニシャライザ
    init(followingId: String) {
        self.init(
            id: followingId,
            followingId: followingId,
            createdAt: Date()
        )
    }
}

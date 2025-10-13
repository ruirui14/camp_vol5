// Models/User.swift
// ユーザー情報を表す純粋なデータモデル
// データ変換ロジックはRepositoryレイヤーに移動

import Foundation

/// ユーザー情報を表すドメインモデル
/// ビジネスロジックやデータ変換を含まない純粋なデータ構造
struct User: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let inviteCode: String
    let allowQRRegistration: Bool
    let followingUserIds: [String]
    let createdAt: Date?
    let updatedAt: Date?

    // MARK: - Initialization

    /// 標準イニシャライザ
    init(
        id: String,
        name: String,
        inviteCode: String,
        allowQRRegistration: Bool,
        followingUserIds: [String],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.allowQRRegistration = allowQRRegistration
        self.followingUserIds = followingUserIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Convenience Initializers

    /// 新規ユーザー作成用のコンビニエンスイニシャライザ
    init(id: String, name: String) {
        self.init(
            id: id,
            name: name,
            inviteCode: UUID().uuidString,
            allowQRRegistration: false,
            followingUserIds: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

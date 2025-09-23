// Services/LocalFollowService.swift
// ログインしていないユーザーのフォロー状況をローカルに保存するサービス

import Foundation
import Combine

/// ローカルフォロー管理サービス
final class LocalFollowService: ObservableObject {
    static let shared = LocalFollowService()

    @Published private(set) var followingUserIds: Set<String> = []

    private let userDefaultsKey = "LocalFollowingUserIds"

    private init() {
        loadFollowingUserIds()
    }

    // MARK: - Public Methods

    /// ユーザーをフォロー
    func followUser(_ userId: String) {
        followingUserIds.insert(userId)
        saveFollowingUserIds()
    }

    /// ユーザーのフォローを解除
    func unfollowUser(_ userId: String) {
        followingUserIds.remove(userId)
        saveFollowingUserIds()
    }

    /// ユーザーをフォローしているかチェック
    func isFollowing(_ userId: String) -> Bool {
        return followingUserIds.contains(userId)
    }

    /// ローカルフォローデータをクリア（ログイン時に呼ばれる）
    func clearLocalFollowData() {
        followingUserIds.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Private Methods

    private func loadFollowingUserIds() {
        if let savedIds = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            followingUserIds = Set(savedIds)
        }
    }

    private func saveFollowingUserIds() {
        UserDefaults.standard.set(Array(followingUserIds), forKey: userDefaultsKey)
    }
}
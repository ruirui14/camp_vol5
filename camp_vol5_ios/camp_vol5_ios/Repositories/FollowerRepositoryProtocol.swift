// Repositories/FollowerRepositoryProtocol.swift
// フォロワー管理のRepository抽象化プロトコル
// テスタビリティとデータソースの切り替えを容易にする

import Combine
import Foundation

/// フォロワー情報の永続化層抽象化プロトコル
/// 実装例: FirestoreFollowerRepository
protocol FollowerRepositoryProtocol {
    /// 指定ユーザーのフォロワーを追加
    /// - Parameters:
    ///   - userId: フォローされるユーザーID
    ///   - follower: フォロワー情報
    /// - Returns: 成功/失敗を返すPublisher
    func addFollower(userId: String, follower: Follower) -> AnyPublisher<Void, Error>

    /// 指定ユーザーのフォロワーを削除
    /// - Parameters:
    ///   - userId: フォローされているユーザーID
    ///   - followerId: 削除するフォロワーのID
    /// - Returns: 成功/失敗を返すPublisher
    func removeFollower(userId: String, followerId: String) -> AnyPublisher<Void, Error>

    /// 指定ユーザーのフォロワー一覧を取得
    /// - Parameter userId: ユーザーID
    /// - Returns: フォロワー配列を返すPublisher
    func fetchFollowers(userId: String) -> AnyPublisher<[Follower], Error>

    /// 特定のフォロワー情報を取得
    /// - Parameters:
    ///   - userId: フォローされているユーザーID
    ///   - followerId: フォロワーのID
    /// - Returns: フォロワー情報のオプショナルPublisher
    func fetchFollower(userId: String, followerId: String) -> AnyPublisher<Follower?, Error>

    /// フォロワーの通知設定を更新
    /// - Parameters:
    ///   - userId: フォローされているユーザーID
    ///   - followerId: フォロワーのID
    ///   - enabled: 通知の有効/無効
    /// - Returns: 成功/失敗を返すPublisher
    func updateNotificationSetting(
        userId: String,
        followerId: String,
        enabled: Bool
    ) -> AnyPublisher<Void, Error>

    /// フォロワーのFCMトークンを更新
    /// - Parameters:
    ///   - userId: フォローされているユーザーID
    ///   - followerId: フォロワーのID
    ///   - fcmToken: 新しいFCMトークン
    /// - Returns: 成功/失敗を返すPublisher
    func updateFCMToken(
        userId: String,
        followerId: String,
        fcmToken: String
    ) -> AnyPublisher<Void, Error>

    /// 複数ユーザーの特定フォロワー情報をバッチ取得（N+1問題の解決）
    /// - Parameters:
    ///   - userIds: フォローされているユーザーIDの配列
    ///   - followerId: フォロワーのID（現在ログイン中のユーザー）
    /// - Returns: ユーザーIDをキーとするFollower辞書のPublisher
    func fetchFollowersForMultipleUsers(
        userIds: [String],
        followerId: String
    ) -> AnyPublisher<[String: Follower?], Error>
}

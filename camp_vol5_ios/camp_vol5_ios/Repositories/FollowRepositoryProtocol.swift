// Repositories/FollowRepositoryProtocol.swift
// フォロー/アンフォロー操作のバッチ処理を提供するリポジトリのプロトコル
// データ整合性を保証するため、Firestore Batch Writeを使用

import Combine
import Foundation

/// フォロー/アンフォロー操作のリポジトリプロトコル
/// Batch Writeを使用してアトミックな操作を保証
protocol FollowRepositoryProtocol {
    /// フォロー操作（following と followers を同時に追加）
    /// - Parameters:
    ///   - currentUserId: フォローするユーザーのID
    ///   - targetUserId: フォロー対象のユーザーID
    ///   - fcmToken: プッシュ通知用のFCMトークン（オプション）
    /// - Returns: 操作完了を示すPublisher
    func followUser(
        currentUserId: String,
        targetUserId: String,
        fcmToken: String?
    ) -> AnyPublisher<Void, Error>

    /// アンフォロー操作（following と followers を同時に削除）
    /// - Parameters:
    ///   - currentUserId: アンフォローするユーザーのID
    ///   - targetUserId: アンフォロー対象のユーザーID
    /// - Returns: 操作完了を示すPublisher
    func unfollowUser(
        currentUserId: String,
        targetUserId: String
    ) -> AnyPublisher<Void, Error>
}

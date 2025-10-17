// Services/Protocols/NotificationServiceProtocol.swift
// プッシュ通知管理サービスの抽象化プロトコル

import Combine
import Foundation

/// FCMトークン管理とプッシュ通知設定のサービスプロトコル
protocol NotificationServiceProtocol {
    /// FCMトークンを取得して保存
    /// - Parameter userId: ユーザーID
    /// - Returns: 成功/失敗を返すPublisher
    func registerFCMToken(userId: String) -> AnyPublisher<Void, Error>

    /// フォロー先のfollowersコレクションにFCMトークンを更新
    /// - Parameters:
    ///   - followingIds: フォロー先のユーザーID配列
    ///   - currentUserId: 現在のユーザーID
    /// - Returns: 成功/失敗を返すPublisher
    func updateFCMTokenForFollowings(
        followingIds: [String],
        currentUserId: String
    ) -> AnyPublisher<Void, Error>

    /// 現在のFCMトークンを取得（キャッシュ）
    var currentFCMToken: String? { get }
}

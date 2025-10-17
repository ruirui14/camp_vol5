// Repositories/FollowingRepositoryProtocol.swift
// フォロー管理のRepository抽象化プロトコル
// テスタビリティとデータソースの切り替えを容易にする

import Combine
import Foundation

/// フォロー情報の永続化層抽象化プロトコル
/// 実装例: FirestoreFollowingRepository
protocol FollowingRepositoryProtocol {
    /// 指定ユーザーのフォロー先を追加
    /// - Parameters:
    ///   - userId: フォローするユーザーID
    ///   - following: フォロー先情報
    /// - Returns: 成功/失敗を返すPublisher
    func addFollowing(userId: String, following: Following) -> AnyPublisher<Void, Error>

    /// 指定ユーザーのフォロー先を削除
    /// - Parameters:
    ///   - userId: フォローしているユーザーID
    ///   - followingId: 削除するフォロー先のID
    /// - Returns: 成功/失敗を返すPublisher
    func removeFollowing(userId: String, followingId: String) -> AnyPublisher<Void, Error>

    /// 指定ユーザーのフォロー先一覧を取得
    /// - Parameter userId: ユーザーID
    /// - Returns: フォロー先配列を返すPublisher
    func fetchFollowings(userId: String) -> AnyPublisher<[Following], Error>
}

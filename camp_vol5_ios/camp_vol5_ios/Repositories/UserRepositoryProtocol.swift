// Repositories/UserRepositoryProtocol.swift
// ユーザーデータの永続化層を抽象化するプロトコル
// クリーンアーキテクチャのRepository パターンを実装

import Combine
import Foundation

/// ユーザーデータの永続化を担当するRepositoryのプロトコル
/// データソース（Firestore, CoreData等）の実装詳細を隠蔽
protocol UserRepositoryProtocol {
    /// ユーザーを作成
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - name: ユーザー名
    /// - Returns: 作成されたUserのPublisher
    func create(userId: String, name: String) -> AnyPublisher<User, Error>

    /// ユーザーを取得
    /// - Parameter userId: ユーザーID
    /// - Returns: Userのオプショナル Publisher
    func fetch(userId: String) -> AnyPublisher<User?, Error>

    /// ユーザーを更新
    /// - Parameter user: 更新するUser
    /// - Returns: 完了通知のPublisher
    func update(_ user: User) -> AnyPublisher<Void, Error>

    /// ユーザーを削除
    /// - Parameter userId: ユーザーID
    /// - Returns: 完了通知のPublisher
    func delete(userId: String) -> AnyPublisher<Void, Error>

    /// 招待コードでユーザーを検索
    /// - Parameter inviteCode: 招待コード
    /// - Returns: 検索結果のUserオプショナル Publisher
    func findByInviteCode(_ inviteCode: String) -> AnyPublisher<User?, Error>

    /// 複数のユーザーを取得
    /// - Parameter userIds: ユーザーIDの配列
    /// - Returns: Userの配列Publisher
    func fetchMultiple(userIds: [String]) -> AnyPublisher<[User], Error>

    /// 最大接続数ランキングを取得
    /// - Parameter limit: 取得件数
    /// - Returns: ランキング順のUserの配列Publisher
    func fetchMaxConnectionsRanking(limit: Int) -> AnyPublisher<[User], Error>
}

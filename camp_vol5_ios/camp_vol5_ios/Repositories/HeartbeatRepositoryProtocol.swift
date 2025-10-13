// Repositories/HeartbeatRepositoryProtocol.swift
// 心拍データの永続化層を抽象化するプロトコル
// クリーンアーキテクチャのRepository パターンを実装

import Combine
import Foundation

/// 心拍データの永続化を担当するRepositoryのプロトコル
/// データソース（Firebase Realtime Database等）の実装詳細を隠蔽
protocol HeartbeatRepositoryProtocol {
    /// 心拍データを一度だけ取得
    /// - Parameter userId: ユーザーID
    /// - Returns: Heartbeatのオプショナル Publisher（エラーあり）
    func fetchOnce(userId: String) -> AnyPublisher<Heartbeat?, Error>

    /// 心拍データをリアルタイムで監視
    /// - Parameter userId: ユーザーID
    /// - Returns: Heartbeatのオプショナル Publisher（エラーなし、nilで無効データを表現）
    func subscribe(userId: String) -> AnyPublisher<Heartbeat?, Never>

    /// 心拍データの監視を停止
    /// - Parameter userId: ユーザーID
    func unsubscribe(userId: String)
}

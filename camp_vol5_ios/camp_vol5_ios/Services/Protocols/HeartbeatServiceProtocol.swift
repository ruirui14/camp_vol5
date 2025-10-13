// Services/Protocols/HeartbeatServiceProtocol.swift
// HeartbeatServiceのプロトコル定義 - 依存性注入とテスタビリティのため

import Combine
import Foundation

/// 心拍データの取得・監視を行うサービスのプロトコル
protocol HeartbeatServiceProtocol {
    /// 心拍データを一度だけ取得
    /// - Parameter userId: ユーザーID
    /// - Returns: Heartbeatのパブリッシャー（エラーあり）
    func getHeartbeatOnce(userId: String) -> AnyPublisher<Heartbeat?, Error>

    /// 心拍データをリアルタイムで監視
    /// - Parameter userId: ユーザーID
    /// - Returns: Heartbeatのパブリッシャー（エラーなし、nilで無効データを表現）
    func subscribeToHeartbeat(userId: String) -> AnyPublisher<Heartbeat?, Never>

    /// 心拍データの監視を停止
    /// - Parameter userId: ユーザーID
    func unsubscribeFromHeartbeat(userId: String)
}

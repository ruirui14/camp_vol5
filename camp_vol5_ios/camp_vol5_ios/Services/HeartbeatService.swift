// Services/HeartbeatService.swift
// 心拍データのビジネスロジックを提供するサービス
// Repository層を使用してデータアクセスを実行

import Combine
import Foundation

class HeartbeatService: HeartbeatServiceProtocol {
    static let shared = HeartbeatService()
    private let repository: HeartbeatRepositoryProtocol
    private let heartbeatValidityDuration: TimeInterval = 5 * 60  // 5分

    init(repository: HeartbeatRepositoryProtocol = FirebaseHeartbeatRepository()) {
        self.repository = repository
    }

    // MARK: - Heartbeat Operations

    /// 心拍データを一度だけ取得する（リスト画面用）
    func getHeartbeatOnce(userId: String) -> AnyPublisher<Heartbeat?, Error> {
        return repository.fetchOnce(userId: userId)
            .map { heartbeat in
                guard let heartbeat = heartbeat else {
                    return nil
                }

                // 5分以内のデータかどうか確認（現在は無効化）
                // let timeDifference = Date().timeIntervalSince(heartbeat.timestamp)
                // if timeDifference <= self.heartbeatValidityDuration {
                //     return heartbeat
                // } else {
                //     return nil
                // }
                return heartbeat
            }
            .eraseToAnyPublisher()
    }

    /// 心拍データの継続監視を開始する（詳細画面用）
    func subscribeToHeartbeat(userId: String) -> AnyPublisher<Heartbeat?, Never> {
        return repository.subscribe(userId: userId)
            .map { heartbeat in
                guard let heartbeat = heartbeat else {
                    return nil
                }

                // テスト用に5分チェック無効化
                return heartbeat
                // let timeDifference = Date().timeIntervalSince(heartbeat.timestamp)
                // if timeDifference <= self.heartbeatValidityDuration {
                //     return heartbeat
                // } else {
                //     print("⏰ データが古すぎます: \(timeDifference)秒前")
                //     return nil
                // }
            }
            .eraseToAnyPublisher()
    }

    /// 心拍データの監視を停止する
    func unsubscribeFromHeartbeat(userId: String) {
        repository.unsubscribe(userId: userId)
    }

    // MARK: - Connection Count Operations

    /// 接続数をリアルタイムで監視
    func subscribeToConnectionCount(userId: String) -> AnyPublisher<Int, Never> {
        return repository.subscribeToConnectionCount(userId: userId)
    }

    /// 接続数の監視を停止
    func unsubscribeFromConnectionCount(userId: String) {
        repository.unsubscribeFromConnectionCount(userId: userId)
    }

    /// 複数ユーザーの心拍データを一度に取得（N+1問題の解決）
    /// - Parameter userIds: ユーザーIDの配列
    /// - Returns: ユーザーIDをキーとするHeartbeat辞書のPublisher
    func getHeartbeatsForMultipleUsers(userIds: [String]) -> AnyPublisher<
        [String: Heartbeat?], Error
    > {
        return repository.fetchMultiple(userIds: userIds)
            .map { heartbeatsDict in
                // 各ハートビートに対して5分チェックを適用（現在は無効化）
                var result: [String: Heartbeat?] = [:]
                for (userId, heartbeat) in heartbeatsDict {
                    result[userId] = heartbeat
                    // 5分以内のデータかどうか確認（現在は無効化）
                    // if let heartbeat = heartbeat {
                    //     let timeDifference = Date().timeIntervalSince(heartbeat.timestamp)
                    //     result[userId] = timeDifference <= self.heartbeatValidityDuration ? heartbeat : nil
                    // } else {
                    //     result[userId] = nil
                    // }
                }
                return result
            }
            .eraseToAnyPublisher()
    }
}

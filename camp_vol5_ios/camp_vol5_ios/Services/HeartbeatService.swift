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
}

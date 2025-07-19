// Services/HeartbeatService.swift
// Firebase Realtime Databaseを使用した心拍データの操作を提供するサービス

import Combine
import Firebase
import FirebaseDatabase
import Foundation

class HeartbeatService {
    static let shared = HeartbeatService()
    private let database = Database.database()
    private let heartbeatValidityDuration: TimeInterval = 5 * 60  // 5分

    private init() {}

    // MARK: - Heartbeat Operations

    /// 心拍データを一度だけ取得する（リスト画面用）
    func getHeartbeatOnce(userId: String) -> AnyPublisher<Heartbeat?, Error> {
        print("getHeartbeatOnce")
        print(userId)
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "HeartbeatService", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }

            let ref = self.database.reference().child("live_heartbeats").child(userId)
            print(ref)

            ref.observeSingleEvent(of: .value) { snapshot in
                if let data = snapshot.value as? [String: Any] {
                    if let heartbeat = Heartbeat(from: data, userId: userId) {
                        print("heartbeat")
                        print(heartbeat)
                        // 5分以内のデータかどうか確認
                        // let timeDifference = Date().timeIntervalSince(heartbeat.timestamp)
                        // if timeDifference <= self.heartbeatValidityDuration {
                        //     promise(.success(heartbeat))
                        // } else {
                        //     promise(.success(nil))
                        // }
                        promise(.success(heartbeat))
                    } else {
                        promise(.success(nil))
                    }
                } else {
                    promise(.success(nil))
                }
            } withCancel: { error in
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    /// 心拍データの継続監視を開始する（詳細画面用）
    func subscribeToHeartbeat(userId: String) -> AnyPublisher<Heartbeat?, Never> {
        let subject = PassthroughSubject<Heartbeat?, Never>()
        let ref = database.reference().child("live_heartbeats").child(userId)

        ref.observe(.value) { [weak self] snapshot in
            guard let self = self else { return }

            if let data = snapshot.value as? [String: Any] {
                if let heartbeat = Heartbeat(from: data, userId: userId) {
                    // テスト用に5分チェック無効化
                    subject.send(heartbeat)
                    // let timeDifference = Date().timeIntervalSince(heartbeat.timestamp)
                    // if timeDifference <= self.heartbeatValidityDuration {
                    //     subject.send(heartbeat)
                    // } else {
                    //     print("⏰ データが古すぎます: \(timeDifference)秒前")
                    //     subject.send(nil)
                    // }
                } else {
                    print("❌ 心拍データのパースに失敗")
                    subject.send(nil)
                }
            } else {
                print("❌ データが見つからないか形式が不正")
                subject.send(nil)
            }
        }

        return subject.eraseToAnyPublisher()
    }

    /// 心拍データの監視を停止する
    func unsubscribeFromHeartbeat(userId: String) {
        let ref = database.reference().child("live_heartbeats").child(userId)
        ref.removeAllObservers()
    }
}

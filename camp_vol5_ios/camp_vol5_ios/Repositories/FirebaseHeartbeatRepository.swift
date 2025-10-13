// Repositories/FirebaseHeartbeatRepository.swift
// Firebase Realtime Databaseを使用したHeartbeatRepositoryの実装
// データ変換ロジック（Model ↔ Realtime Database）をここに集約

import Combine
import Firebase
import FirebaseDatabase
import Foundation

/// Firebase Realtime DatabaseベースのHeartbeatRepository実装
class FirebaseHeartbeatRepository: HeartbeatRepositoryProtocol {
    private let database: Database

    init(database: Database = Database.database()) {
        self.database = database
    }

    // MARK: - Public Methods

    func fetchOnce(userId: String) -> AnyPublisher<Heartbeat?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            let ref = self.database.reference().child("live_heartbeats").child(userId)

            ref.observeSingleEvent(of: .value) { snapshot in
                if let data = snapshot.value as? [String: Any] {
                    let heartbeat = self.fromRealtimeDatabase(data, userId: userId)
                    promise(.success(heartbeat))
                } else {
                    promise(.success(nil))
                }
            } withCancel: { error in
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func subscribe(userId: String) -> AnyPublisher<Heartbeat?, Never> {
        let subject = PassthroughSubject<Heartbeat?, Never>()
        let ref = database.reference().child("live_heartbeats").child(userId)

        ref.observe(.value) { [weak self] snapshot in
            guard let self = self else {
                subject.send(nil)
                return
            }

            if let data = snapshot.value as? [String: Any] {
                let heartbeat = self.fromRealtimeDatabase(data, userId: userId)
                subject.send(heartbeat)
            } else {
                subject.send(nil)
            }
        }

        return subject.eraseToAnyPublisher()
    }

    func unsubscribe(userId: String) {
        let ref = database.reference().child("live_heartbeats").child(userId)
        ref.removeAllObservers()
    }

    func saveHeartRate(userId: String, bpm: Int) {
        let ref = database.reference().child("live_heartbeats").child(userId)

        // タイムスタンプをミリ秒単位に変換
        let timestampMillis = Date().timeIntervalSince1970 * 1000

        let data: [String: Any] = [
            "bpm": bpm,
            "timestamp": timestampMillis,
        ]

        ref.setValue(data) { error, _ in
            if let error = error {
                print("❌ Firebase保存エラー: \(error.localizedDescription)")
            } else {
                print("✅ 心拍数をFirebaseに保存: \(bpm) bpm, userId: \(userId)")
            }
        }
    }

    // MARK: - Private: Data Transformation

    /// Realtime DatabaseデータをHeartbeatに変換
    /// - Parameters:
    ///   - data: Realtime Databaseから取得したデータ
    ///   - userId: ユーザーID
    /// - Returns: 変換されたHeartbeat、変換失敗時はnil
    private func fromRealtimeDatabase(_ data: [String: Any], userId: String) -> Heartbeat? {
        guard let bpm = data["bpm"] as? Int,
            let timestamp = data["timestamp"] as? TimeInterval
        else {
            return nil
        }

        // Firebase Realtime Databaseのタイムスタンプはミリ秒単位
        let date = Date(timeIntervalSince1970: timestamp / 1000)

        return Heartbeat(userId: userId, bpm: bpm, timestamp: date)
    }
}

// Repositories/FirebaseHeartbeatRepository.swift
// Firebase Realtime Databaseを使用したHeartbeatRepositoryの実装
// データ変換ロジック（Model ↔ Realtime Database）をここに集約

import Combine
import Firebase
import FirebaseDatabase
import FirebasePerformance
import Foundation

/// Firebase Realtime DatabaseベースのHeartbeatRepository実装
class FirebaseHeartbeatRepository: HeartbeatRepositoryProtocol {
    private let database: Database
    private var connectionCountHandles: [String: DatabaseHandle] = [:]  // userId -> connections observer handle
    private var heartbeatObserverHandles: [String: [DatabaseHandle]] = [:]  // userId -> [observer handles]
    private var observerCount: [String: Int] = [:]  // userId -> active observer count

    init(database: Database = Database.database()) {
        self.database = database
    }

    // MARK: - Public Methods

    func fetchOnce(userId: String) -> AnyPublisher<Heartbeat?, Error> {
        let trace = PerformanceMonitor.shared.startTrace(
            PerformanceMonitor.DataTrace.fetchHeartbeat)

        return Future { [weak self] promise in
            guard let self = self else {
                PerformanceMonitor.shared.stopTrace(trace)
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            let ref = self.database.reference().child("live_heartbeats").child(userId)

            ref.observeSingleEvent(of: .value) { snapshot in
                PerformanceMonitor.shared.stopTrace(trace)
                if let data = snapshot.value as? [String: Any] {
                    let heartbeat = self.fromRealtimeDatabase(data, userId: userId)
                    promise(.success(heartbeat))
                } else {
                    promise(.success(nil))
                }
            } withCancel: { error in
                PerformanceMonitor.shared.stopTrace(trace)
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }

    func subscribe(userId: String) -> AnyPublisher<Heartbeat?, Never> {
        let subject = PassthroughSubject<Heartbeat?, Never>()
        let ref = database.reference().child("live_heartbeats").child(userId)

        let handle = ref.observe(.value) { [weak self] snapshot in
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

        // observerハンドルを保存
        if heartbeatObserverHandles[userId] == nil {
            heartbeatObserverHandles[userId] = []
        }
        heartbeatObserverHandles[userId]?.append(handle)

        // observer数をカウント
        let count = (observerCount[userId] ?? 0) + 1
        observerCount[userId] = count

        // 注: 接続数カウンター機能は複雑さを避けるため無効化
        // 必要に応じて将来再実装可能

        return subject.eraseToAnyPublisher()
    }

    func unsubscribe(userId: String) {
        // observer数を減らす
        let currentCount = observerCount[userId] ?? 0
        let newCount = max(0, currentCount - 1)
        observerCount[userId] = newCount

        // 最後のobserverハンドルを削除
        if var handles = heartbeatObserverHandles[userId], !handles.isEmpty {
            let handleToRemove = handles.removeLast()
            heartbeatObserverHandles[userId] = handles

            let ref = database.reference().child("live_heartbeats").child(userId)
            ref.removeObserver(withHandle: handleToRemove)
        }

        // 全てのobserverが削除されたらクリーンアップ
        if newCount == 0 {
            // クリーンアップ
            heartbeatObserverHandles.removeValue(forKey: userId)
            observerCount.removeValue(forKey: userId)
        }
    }

    func saveHeartRate(userId: String, bpm: Int) {
        let trace = PerformanceMonitor.shared.startTrace(PerformanceMonitor.DataTrace.saveHeartRate)

        let ref = database.reference().child("live_heartbeats").child(userId)

        // タイムスタンプをミリ秒単位に変換
        let timestampMillis = Date().timeIntervalSince1970 * 1000

        let data: [String: Any] = [
            "bpm": bpm,
            "timestamp": timestampMillis,
        ]

        ref.setValue(data) { error, _ in
            PerformanceMonitor.shared.stopTrace(trace)
            if let error = error {
                print("❌ Firebase保存エラー: \(error.localizedDescription)")
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

    // MARK: - Connection Count Subscription

    /// 接続数をリアルタイムで監視
    /// - Parameter userId: ユーザーID
    /// - Returns: 接続数のPublisher
    func subscribeToConnectionCount(userId: String) -> AnyPublisher<Int, Never> {
        let subject = PassthroughSubject<Int, Never>()
        let ref = database.reference()
            .child("live_heartbeats")
            .child(userId)
            .child("connections")

        let handle = ref.observe(.value) { snapshot in
            let count = snapshot.value as? Int ?? 0
            subject.send(count)
        }

        connectionCountHandles[userId] = handle

        return subject.eraseToAnyPublisher()
    }

    /// 接続数の監視を停止
    /// - Parameter userId: ユーザーID
    func unsubscribeFromConnectionCount(userId: String) {
        guard let handle = connectionCountHandles[userId] else {
            return
        }

        let ref = database.reference()
            .child("live_heartbeats")
            .child(userId)
            .child("connections")

        ref.removeObserver(withHandle: handle)
        connectionCountHandles.removeValue(forKey: userId)
    }
}

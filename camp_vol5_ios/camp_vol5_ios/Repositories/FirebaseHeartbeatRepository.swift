// Repositories/FirebaseHeartbeatRepository.swift
// Firebase Realtime Databaseを使用したHeartbeatRepositoryの実装
// データ変換ロジック（Model ↔ Realtime Database）をここに集約

import Combine
import Firebase
import FirebaseDatabase
import FirebaseFirestore
import FirebasePerformance
import Foundation

/// Firebase Realtime DatabaseベースのHeartbeatRepository実装
class FirebaseHeartbeatRepository: HeartbeatRepositoryProtocol {
    private let database: Database
    private var connectionHandles: [String: DatabaseHandle] = [:]  // userId -> .info/connected observer handle
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

        // 接続数管理: .info/connectedを監視して自動的に接続数を管理
        setupConnectionCounter(for: userId)

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

            // 接続数管理の監視を停止
            removeConnectionCounter(for: userId)
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
        print("🔗 接続数の監視を開始: \(userId)")

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
        print("🔗 接続数の監視を停止: \(userId)")
    }

    // MARK: - Private: Connection Counter Management

    /// 接続数カウンターを設定
    /// .info/connectedを監視し、接続時に+1、切断時に自動的に-1する
    /// - Parameter userId: 対象ユーザーID
    private func setupConnectionCounter(for userId: String) {
        // 既に監視中の場合はスキップ
        guard connectionHandles[userId] == nil else {
            print("⚠️ 接続数カウンターは既に設定されています: \(userId)")
            return
        }

        let connectedRef = Database.database().reference(withPath: ".info/connected")
        let handle = connectedRef.observe(.value) { [weak self] snapshot in
            guard let self = self,
                let connected = snapshot.value as? Bool,
                connected
            else {
                return
            }

            // 接続確立時の処理
            let connectionsRef = self.database.reference()
                .child("live_heartbeats")
                .child(userId)
                .child("connections")

            // トランザクションで安全に接続数を+1
            connectionsRef.runTransactionBlock { currentData in
                var value = currentData.value as? Int ?? 0
                value += 1
                currentData.value = value
                return TransactionResult.success(withValue: currentData)
            } andCompletionBlock: { [weak self] error, committed, snapshot in
                if let error = error {
                    print("❌ 接続数の増加に失敗: \(error.localizedDescription)")
                } else if committed {
                    let count = snapshot?.value as? Int ?? 0
                    print("✅ 接続数を増加: \(userId), 現在の接続数: \(count)")

                    // 最大接続数を更新
                    self?.updateMaxConnectionsIfNeeded(userId: userId, currentCount: count)

                    // 切断時に自動的に-1する設定
                    self?.database.reference()
                        .child("live_heartbeats")
                        .child(userId)
                        .child("connections")
                        .onDisconnectSetValue(max(0, count - 1)) { error, _ in
                            if let error = error {
                                print("❌ onDisconnect設定に失敗: \(error.localizedDescription)")
                            } else {
                                print("✅ onDisconnect設定完了: 切断時は\(count - 1)に")
                            }
                        }
                }
            }
        }

        connectionHandles[userId] = handle
        print("🔗 接続数カウンターを設定: \(userId)")
    }

    /// 接続数カウンターの監視を停止
    /// - Parameter userId: 対象ユーザーID
    private func removeConnectionCounter(for userId: String) {
        guard let handle = connectionHandles[userId] else {
            return
        }

        // .info/connectedの監視を停止
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.removeObserver(withHandle: handle)
        connectionHandles.removeValue(forKey: userId)

        // 手動で接続数を-1
        let connectionsRef = database.reference()
            .child("live_heartbeats")
            .child(userId)
            .child("connections")

        connectionsRef.runTransactionBlock { currentData in
            var value = currentData.value as? Int ?? 0
            value = max(0, value - 1)
            currentData.value = value
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, committed, snapshot in
            if let error = error {
                print("❌ 接続数の減少に失敗: \(error.localizedDescription)")
            } else if committed {
                print("✅ 接続数を減少: \(userId), 現在の接続数: \(snapshot?.value ?? "unknown")")
            }
        }

        // onDisconnect操作をキャンセル
        connectionsRef.cancelDisconnectOperations { error, _ in
            if let error = error {
                print("❌ onDisconnectキャンセルに失敗: \(error.localizedDescription)")
            } else {
                print("✅ onDisconnectをキャンセル: \(userId)")
            }
        }

        print("🔗 接続数カウンターを削除: \(userId)")
    }

    /// 最大接続数を更新（現在の接続数が最大を超えた場合のみ）
    /// バックグラウンドで実行されるため、メインスレッドをブロックしない
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - currentCount: 現在の接続数
    private func updateMaxConnectionsIfNeeded(userId: String, currentCount: Int) {
        print("☑️ updateMaxConnectionsIfNeeded: \(userId), currentCount: \(currentCount)")

        // バックグラウンドで実行
        Task.detached(priority: .utility) {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(userId)

            db.runTransaction({ transaction, errorPointer -> Any? in
                let userDocument: DocumentSnapshot
                do {
                    try userDocument = transaction.getDocument(userRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }

                let currentMaxConnections = userDocument.data()?["maxConnections"] as? Int ?? 0

                // 現在の接続数が最大接続数を超えた場合のみ更新
                if currentCount > currentMaxConnections {
                    transaction.updateData(
                        [
                            "maxConnections": currentCount,
                            "maxConnectionsUpdatedAt": FieldValue.serverTimestamp(),
                        ], forDocument: userRef)
                    print("🏆 最大接続数を更新: \(userId), \(currentMaxConnections) → \(currentCount)")
                }

                return nil
            }) { _, error in
                if let error = error {
                    print("❌ 最大接続数の更新に失敗: \(error.localizedDescription)")
                }
            }
        }
    }
}

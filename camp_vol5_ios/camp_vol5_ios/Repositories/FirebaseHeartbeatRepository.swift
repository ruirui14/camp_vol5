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
    private var connectionHandles: [String: DatabaseHandle] = [:]  // userId -> .info/connected observer handle

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

        // 接続数管理: .info/connectedを監視して自動的に接続数を管理
        setupConnectionCounter(for: userId)

        return subject.eraseToAnyPublisher()
    }

    func unsubscribe(userId: String) {
        let ref = database.reference().child("live_heartbeats").child(userId)
        ref.removeAllObservers()

        // 接続数管理の監視を停止
        removeConnectionCounter(for: userId)
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
}

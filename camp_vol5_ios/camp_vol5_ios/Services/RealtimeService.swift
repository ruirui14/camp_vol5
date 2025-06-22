import Combine
// Services/RealtimeService.swift
import Firebase
import FirebaseDatabase

class RealtimeService: ObservableObject {
    static let shared = RealtimeService()

    private let database: Database
    private var cancellables = Set<AnyCancellable>()
    private let heartbeatValidityDuration: TimeInterval = 5 * 60  // 5分

    @Published var connectionStatus: ConnectionStatus = .disconnected

    enum ConnectionStatus {
        case connected, disconnected
        case error(String)

        var description: String {
            switch self {
            case .connected: return "接続中"
            case .disconnected: return "未接続"
            case .error(let message): return "エラー: \(message)"
            }
        }
    }

    private init() {
        self.database = Database.database()
        setupConnectionMonitoring()
    }

    // MARK: - Connection Monitoring

    private func setupConnectionMonitoring() {
        let connectedRef = database.reference(withPath: ".info/connected")
        connectedRef.observe(.value) { [weak self] snapshot in
            DispatchQueue.main.async {
                if let connected = snapshot.value as? Bool, connected {
                    self?.connectionStatus = .connected
                } else {
                    self?.connectionStatus = .disconnected
                }
            }
        }
    }

    // MARK: - Heartbeat Management

    // 心拍データ送信
    func sendHeartbeat(userId: String, bpm: Int) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            let heartbeatData = HeartbeatData(bpm: bpm)

            self?.database.reference()
                .child("live_heartbeats")
                .child(userId)
                .setValue(heartbeatData.toDictionary()) { error, _ in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // 心拍データ受信（単一ユーザー）
    func subscribeToHeartbeat(userId: String) -> AnyPublisher<Heartbeat?, Error>
    {
        return Future<Heartbeat?, Error> { [weak self] promise in
            self?.database.reference()
                .child("live_heartbeats")
                .child(userId)
                .observe(.value) { snapshot in
                    guard let data = snapshot.value as? [String: Any] else {
                        promise(.success(nil))
                        return
                    }

                    guard let heartbeat = Heartbeat(from: data, userId: userId)
                    else {
                        promise(.success(nil))
                        return
                    }

                    // 有効期限チェック
                    let currentTime = Date()
                    let validityThreshold = currentTime.addingTimeInterval(
                        -(self?.heartbeatValidityDuration ?? 300)
                    )  // 300秒前のデータは無視

                    if heartbeat.timestamp > validityThreshold {
                        promise(.success(heartbeat))
                    } else {
                        promise(.success(nil))  // 古いデータは無視
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // 心拍購読停止
    func unsubscribeFromHeartbeat(userId: String) {
        database.reference()
            .child("live_heartbeats")
            .child(userId)
            .removeAllObservers()
    }

    // 複数ユーザーの心拍データ取得（フォロー中のユーザー用）
    func subscribeToMultipleHeartbeats(userIds: [String]) -> AnyPublisher<
        [String: Heartbeat], Error
    > {
        let publishers = userIds.map { userId in
            subscribeToHeartbeat(userId: userId)
                .map { heartbeat in (userId, heartbeat) }
                .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(publishers)
            .scan([String: Heartbeat]()) { result, tuple in
                var newResult = result
                let (userId, heartbeat) = tuple
                if let heartbeat = heartbeat {
                    newResult[userId] = heartbeat
                } else {
                    newResult.removeValue(forKey: userId)
                }
                return newResult
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Active Users

    // アクティブユーザー一覧取得
    func getActiveUsers() -> AnyPublisher<[String], Error> {
        return Future { [weak self] promise in
            self?.database.reference()
                .child("live_heartbeats")
                .observeSingleEvent(of: .value) { snapshot in
                    guard let data = snapshot.value as? [String: [String: Any]]
                    else {
                        promise(.success([]))
                        return
                    }

                    let currentTime = Date().timeIntervalSince1970 * 1000
                    let validityThreshold =
                        currentTime - (self?.heartbeatValidityDuration ?? 300)
                        * 1000

                    let activeUserIds = data.compactMap {
                        (userId, heartbeatData) -> String? in
                        guard
                            let timestamp = heartbeatData["timestamp"]
                                as? TimeInterval,
                            timestamp > validityThreshold
                        else {
                            return nil
                        }
                        return userId
                    }

                    promise(.success(activeUserIds))
                }
        }
        .eraseToAnyPublisher()
    }
}

enum RealtimeError: Error, LocalizedError {
    case invalidData
    case connectionFailed
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidData: return "無効なデータです"
        case .connectionFailed: return "接続に失敗しました"
        case .notAuthenticated: return "認証が必要です"
        }
    }
}

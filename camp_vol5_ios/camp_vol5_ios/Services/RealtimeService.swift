// Services/RealtimeService.swift
import Combine
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

    // 心拍データを1回だけ取得（一覧ページ用）
    func getHeartbeatOnce(userId: String) -> AnyPublisher<Heartbeat?, Error> {
        return Future { [weak self] promise in
            self?.database.reference()
                .child("live_heartbeats")
                .child(userId)
                .observeSingleEvent(of: .value) { snapshot in
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
                    )

                    if heartbeat.timestamp > validityThreshold {
                        promise(.success(heartbeat))
                    } else {
                        promise(.success(nil))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // 心拍データの常時監視（詳細ページ用）
    func subscribeToHeartbeat(userId: String) -> AnyPublisher<Heartbeat?, Never>
    {
        let subject = PassthroughSubject<Heartbeat?, Never>()

        database.reference()
            .child("live_heartbeats")
            .child(userId)
            .observe(.value) { [weak self] snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    subject.send(nil)
                    return
                }

                guard let heartbeat = Heartbeat(from: data, userId: userId)
                else {
                    subject.send(nil)
                    return
                }

                // 有効期限チェック
                let currentTime = Date()
                let validityThreshold = currentTime.addingTimeInterval(
                    -(self?.heartbeatValidityDuration ?? 300)
                )

                if heartbeat.timestamp > validityThreshold {
                    subject.send(heartbeat)
                } else {
                    subject.send(nil)
                }
            }

        return subject.eraseToAnyPublisher()
    }

    // 心拍購読停止
    func unsubscribeFromHeartbeat(userId: String) {
        database.reference()
            .child("live_heartbeats")
            .child(userId)
            .removeAllObservers()
    }

}

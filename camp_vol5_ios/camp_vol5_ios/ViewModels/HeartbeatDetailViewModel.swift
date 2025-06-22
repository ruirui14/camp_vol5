// ViewModels/HeartbeatDetailViewModel.swift
import Combine
import Foundation

class HeartbeatDetailViewModel: ObservableObject {
    @Published var user: User?
    @Published var currentHeartbeat: Heartbeat?
    @Published var isMonitoring: Bool = false
    @Published var connectionStatus: RealtimeService.ConnectionStatus =
        .disconnected
    @Published var errorMessage: String?

    private let userId: String
    private let firestoreService = FirestoreService.shared
    private let realtimeService = RealtimeService.shared
    private var cancellables = Set<AnyCancellable>()
    private var heartbeatSubscription: AnyCancellable?

    init(userId: String) {
        self.userId = userId
        setupBindings()
        loadUserInfo()
    }

    private func setupBindings() {
        // 接続状態の監視
        realtimeService.$connectionStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionStatus, on: self)
            .store(in: &cancellables)
    }

    // ユーザー情報を取得
    private func loadUserInfo() {
        firestoreService.getUser(uid: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: {
                    [weak self] (completion: Subscribers.Completion<Error>) in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] (user: User?) in
                    self?.user = user
                }
            )
            .store(in: &cancellables)
    }

    // 心拍データの常時監視を開始
    func startContinuousMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        heartbeatSubscription = realtimeService.subscribeToHeartbeat(
            userId: userId
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] heartbeat in
            self?.currentHeartbeat = heartbeat
        }
    }

    // 監視を停止
    func stopMonitoring() {
        isMonitoring = false
        heartbeatSubscription?.cancel()
        heartbeatSubscription = nil
        realtimeService.unsubscribeFromHeartbeat(userId: userId)
    }

    // 手動で心拍データを更新
    func refreshHeartbeat() {
        realtimeService.getHeartbeatOnce(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] heartbeat in
                    self?.currentHeartbeat = heartbeat
                }
            )
            .store(in: &cancellables)
    }

    func clearError() {
        errorMessage = nil
    }

    deinit {
        stopMonitoring()
    }
}

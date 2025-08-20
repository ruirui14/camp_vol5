// ViewModels/HeartbeatDetailViewModel.swift
import Combine
import Foundation

class HeartbeatDetailViewModel: ObservableObject {
    @Published var user: User?
    @Published var currentHeartbeat: Heartbeat?
    @Published var isMonitoring: Bool = false
    @Published var errorMessage: String?

    private let userId: String
    private var cancellables = Set<AnyCancellable>()
    private var heartbeatSubscription: AnyCancellable?

    init(userId: String) {
        self.userId = userId
        loadUserInfo()
    }

    init(userWithHeartbeat: UserWithHeartbeat) {
        userId = userWithHeartbeat.user.id
        user = userWithHeartbeat.user
        currentHeartbeat = userWithHeartbeat.heartbeat
    }

    // ユーザー情報を取得
    private func loadUserInfo() {
        UserService.shared.getUser(uid: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: {
                    [weak self] (completion: Subscribers.Completion<Error>) in
                    if case let .failure(error) = completion {
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
        errorMessage = nil  // 監視開始時にエラーをクリア
        heartbeatSubscription = HeartbeatService.shared.subscribeToHeartbeat(userId: userId)
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
        HeartbeatService.shared.unsubscribeFromHeartbeat(userId: userId)
    }

    // 手動で心拍データを更新
    func refreshHeartbeat() {
        HeartbeatService.shared.getHeartbeatOnce(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
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

// ViewModels/ListHeartBeatsViewModel.swift
import Combine
import Foundation

class ListHeartBeatsViewModel: ObservableObject {
    @Published var followingUsersWithHeartbeats: [UserWithHeartbeat] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var user: User?

    private let firestoreService = FirestoreService.shared
    private let realtimeService = RealtimeService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialLoadAttempted = false

    init() {
        setupObservers()
    }

    private func setupObservers() {
        // 認証状態とローディング状態の監視
        Publishers.CombineLatest(
            authService.$isAuthenticated,
            authService.$isLoading
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isAuthenticated, isLoading in
            if !isAuthenticated && !isLoading {
                self?.followingUsersWithHeartbeats = []
                self?.errorMessage = nil
                self?.isLoading = false
                self?.hasInitialLoadAttempted = false
            }
        }
        .store(in: &cancellables)

        // 現在のユーザー情報とローディング状態を同時に監視
        Publishers.CombineLatest(
            authService.$currentUser,
            authService.$isLoading
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] currentUser, isLoading in
            let isGoogleAuthenticated =
                self?.authService.isGoogleAuthenticated ?? false
            self?.user = currentUser

            // Google認証済み、ユーザー情報あり、ローディング中でない場合に初回ロード
            // TODO: 一旦Google認証済みでない場合は、使えないようにしておく
            if let currentUser = currentUser,
                isGoogleAuthenticated,
                !isLoading,
                !(self?.hasInitialLoadAttempted ?? false)  // 初回ロードがまだ実行されていない場合のみtrue
            {
                self?.hasInitialLoadAttempted = true
                self?.loadFollowingUsersWithHeartbeats()
            } else if !isGoogleAuthenticated || currentUser == nil {
                self?.followingUsersWithHeartbeats = []
                self?.errorMessage = nil
                if !isLoading {
                    self?.isLoading = false
                }
                if currentUser == nil {
                    self?.hasInitialLoadAttempted = false
                }
            }
        }
        .store(in: &cancellables)
    }

    // フォロー中のユーザー情報と心拍データを取得
    func loadFollowingUsersWithHeartbeats() {
        guard let currentUserId = authService.currentUser?.id else {
            return
        }

        isLoading = true
        errorMessage = nil

        // 1. フォロー中のユーザー情報を取得
        firestoreService.getFollowingUsers(userId: currentUserId)
            .flatMap {
                [weak self] users -> AnyPublisher<[UserWithHeartbeat], Error> in
                guard let self = self else {
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }

                // ユーザーがいない場合は空配列を返す
                guard !users.isEmpty else {
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }

                // 2. 各ユーザーの心拍データを並行取得
                let heartbeatPublishers = users.map { user in
                    self.realtimeService.getHeartbeatOnce(userId: user.id)
                        .map { heartbeat in
                            UserWithHeartbeat(user: user, heartbeat: heartbeat)
                        }
                        .catch { _ in
                            // エラーが発生した場合は心拍データなしのUserWithHeartbeatを返す
                            Just(UserWithHeartbeat(user: user, heartbeat: nil))
                                .setFailureType(to: Error.self)
                        }
                        .eraseToAnyPublisher()
                }

                // すべての心拍データ取得を並行実行し、結果を収集
                return Publishers.MergeMany(heartbeatPublishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] usersWithHeartbeats in
                    self?.followingUsersWithHeartbeats = usersWithHeartbeats
                }
            )
            .store(in: &cancellables)
    }

    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Helper Models
struct UserWithHeartbeat: Identifiable {
    let id = UUID()
    let user: User
    var heartbeat: Heartbeat?
}

// ViewModels/ListHeartBeatsViewModel.swift
import Combine
import Foundation

class ListHeartBeatsViewModel: ObservableObject {
    @Published var followingUsersWithHeartbeats: [UserWithHeartbeat] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared
    private let realtimeService = RealtimeService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 認証状態とローディング状態の監視
        Publishers.CombineLatest(
            authService.$isAuthenticated,
            authService.$isLoading
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isAuthenticated, isLoading in
            // 認証が完了し、ローディングが終了したらユーザー情報を読み込む
            if isAuthenticated && !isLoading {
                self?.loadFollowingUsersWithHeartbeatsIfNeeded()
            } else if !isAuthenticated && !isLoading {
                // 認証されていない場合はリストをクリア
                self?.followingUsersWithHeartbeats = []
                self?.errorMessage = nil
                self?.isLoading = false
            }
        }
        .store(in: &cancellables)

        // 現在のユーザー情報の監視（Google認証済みの場合）
        authService.$currentUser
            .removeDuplicates { $0?.id == $1?.id }
            .sink { [weak self] user in
                if user != nil {
                    self?.loadFollowingUsersWithHeartbeatsIfNeeded()
                } else {
                    self?.followingUsersWithHeartbeats = []
                    self?.errorMessage = nil
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
    }

    private func loadFollowingUsersWithHeartbeatsIfNeeded() {
        // 既にデータがある場合は読み込みをスキップ
        guard followingUsersWithHeartbeats.isEmpty else { return }

        loadFollowingUsersWithHeartbeats()
    }

    // フォロー中のユーザー情報と心拍データを取得
    func loadFollowingUsersWithHeartbeats() {
        guard let currentUserId = authService.currentUser?.id else {
            // 認証が必要な場合はエラーメッセージを表示しない
            return
        }

        isLoading = true

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

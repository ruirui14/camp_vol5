// ViewModels/ListHeartBeatsViewModel.swift
import Combine
import Foundation

enum SortOption: String, CaseIterable {
    case name = "名前順"
    case timestamp = "新しい順"
    case bpm = "心拍数高い順"
}

class ListHeartBeatsViewModel: ObservableObject {
    @Published var followingUsersWithHeartbeats: [UserWithHeartbeat] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentSortOption: SortOption = .name

    private var authenticationManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        setupBindings()
    }

    func updateAuthenticationManager(_ authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        cancellables.removeAll()
        setupBindings()
    }

    private func setupBindings() {
        // 認証状態、ローディング状態、ユーザー情報を統合して監視
        Publishers.CombineLatest3(
            authenticationManager.$isAuthenticated,
            authenticationManager.$isLoading,
            authenticationManager.$currentUser
        )
        .removeDuplicates { prev, current in
            // 重複実行を防ぐため、変更があった場合のみ処理
            prev.0 == current.0 && prev.1 == current.1 && prev.2?.id == current.2?.id
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isAuthenticated, isLoading, currentUser in
            guard !isLoading else { return }  // ローディング中は何もしない

            if isAuthenticated, currentUser != nil {
                // 認証済みでユーザー情報がある場合のみデータを読み込む
                self?.loadFollowingUsersWithHeartbeatsIfNeeded()
            } else {
                // 認証されていない、またはユーザー情報がない場合はリストをクリア
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
        guard let currentUser = authenticationManager.currentUser else {
            isLoading = false
            return
        }

        isLoading = true

        UserService.shared.getFollowingUsers(followingUserIds: currentUser.followingUserIds)
            .flatMap { users -> AnyPublisher<[UserWithHeartbeat], Error> in
                guard !users.isEmpty else {
                    return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                let heartbeatPublishers = users.map { user in
                    HeartbeatService.shared.getHeartbeatOnce(userId: user.id)
                        .map { heartbeat in
                            UserWithHeartbeat(user: user, heartbeat: heartbeat)
                        }
                        .catch { _ in
                            Just(UserWithHeartbeat(user: user, heartbeat: nil))
                                .setFailureType(to: Error.self)
                        }
                        .eraseToAnyPublisher()
                }
                return Publishers.MergeMany(heartbeatPublishers)
                    .collect()
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] usersWithHeartbeats in
                    self?.followingUsersWithHeartbeats = self?.sortUsers(usersWithHeartbeats, by: self?.currentSortOption ?? .name) ?? usersWithHeartbeats
                }
            )
            .store(in: &cancellables)
    }

    func clearError() {
        errorMessage = nil
    }

    func changeSortOption(_ sortOption: SortOption) {
        currentSortOption = sortOption
        followingUsersWithHeartbeats = sortUsers(followingUsersWithHeartbeats, by: sortOption)
    }

    private func sortUsers(_ users: [UserWithHeartbeat], by sortOption: SortOption) -> [UserWithHeartbeat] {
        switch sortOption {
        case .name:
            return users.sorted { $0.user.name < $1.user.name }
        case .timestamp:
            return users.sorted { user1, user2 in
                let timestamp1 = user1.heartbeat?.timestamp ?? Date.distantPast
                let timestamp2 = user2.heartbeat?.timestamp ?? Date.distantPast
                return timestamp1 > timestamp2
            }
        case .bpm:
            return users.sorted { user1, user2 in
                let bpm1 = user1.heartbeat?.bpm ?? 0
                let bpm2 = user2.heartbeat?.bpm ?? 0
                return bpm1 > bpm2
            }
        }
    }
}

// MARK: - Helper Models

struct UserWithHeartbeat: Identifiable, Hashable {
    var id: String {
        print("UserWithHeartbeat.id accessed for user: \(user.name), returning: \(user.id)")
        return user.id
    }
    let user: User
    var heartbeat: Heartbeat?

    func hash(into hasher: inout Hasher) {
        hasher.combine(user.id)
        hasher.combine(user.name)
        hasher.combine(heartbeat?.bpm)
    }

    static func == (lhs: UserWithHeartbeat, rhs: UserWithHeartbeat) -> Bool {
        return lhs.user.id == rhs.user.id
    }
}

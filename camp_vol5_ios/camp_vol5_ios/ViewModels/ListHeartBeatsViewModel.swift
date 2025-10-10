// ViewModels/ListHeartBeatsViewModel.swift
// フォローユーザー一覧画面のビューモデル - MVVM設計パターンに従いビジネスロジックを集約
// ソート機能、データ取得、認証状態管理を責務として持つ

import Combine
import Foundation

enum SortOption: String, CaseIterable {
    case name = "名前順"
    case timestamp = "新しい順"
    case bpm = "心拍数高い順"
}

@MainActor
class ListHeartBeatsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var followingUsersWithHeartbeats: [UserWithHeartbeat] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentSortOption: SortOption = .name

    // MARK: - Private Properties
    private var authenticationManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies
    private let userService: UserService
    private let heartbeatService: HeartbeatService

    // MARK: - Computed Properties
    var hasFollowingUsers: Bool {
        !followingUsersWithHeartbeats.isEmpty
    }

    var isAuthenticated: Bool {
        authenticationManager.isAuthenticated
    }

    // MARK: - Initialization
    init(
        authenticationManager: AuthenticationManager,
        userService: UserService = UserService.shared,
        heartbeatService: HeartbeatService = HeartbeatService.shared
    ) {
        self.authenticationManager = authenticationManager
        self.userService = userService
        self.heartbeatService = heartbeatService
        setupBindings()
    }

    func updateAuthenticationManager(_ authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        cancellables.removeAll()
        setupBindings()
    }

    // MARK: - Public Methods

    func loadData() {
        loadFollowingUsersWithHeartbeats()
    }

    func refreshData() {
        print("🔄 [ListHeartBeatsViewModel] refreshData: 開始")
        clearError()

        guard let currentUserId = authenticationManager.currentUserId else {
            print("⚠️ [ListHeartBeatsViewModel] refreshData: currentUserIdがnil")
            return
        }

        isLoading = true

        // 最新のユーザー情報をFirestoreから取得してからフォローユーザーリストを更新
        userService.getUser(uid: currentUserId)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        print(
                            "❌ [ListHeartBeatsViewModel] refreshData: ユーザー情報取得エラー - \(error.localizedDescription)"
                        )
                        self?.errorMessage = "ユーザー情報の取得に失敗しました"
                        self?.isLoading = false
                    }
                },
                receiveValue: { [weak self] updatedUser in
                    print("✅ [ListHeartBeatsViewModel] refreshData: ユーザー情報取得成功")
                    // AuthenticationManagerのcurrentUserを更新
                    self?.authenticationManager.currentUser = updatedUser
                    // フォローユーザーリストを再読み込み
                    self?.loadFollowingUsersWithHeartbeats()
                }
            )
            .store(in: &cancellables)
    }

    func changeSortOption(_ sortOption: SortOption) {
        currentSortOption = sortOption
        applySorting()
    }

    func clearError() {
        errorMessage = nil
    }

    func unfollowUser(userId: String) {
        print("📤 [ListHeartBeatsViewModel] unfollowUser: 開始 - userId: \(userId)")

        guard let currentUser = authenticationManager.currentUser else {
            print("⚠️ [ListHeartBeatsViewModel] unfollowUser: currentUserがnil")
            errorMessage = "ユーザー情報が取得できません"
            return
        }

        userService.unfollowUser(currentUser: currentUser, targetUserId: userId)
            .flatMap { [weak self] _ -> AnyPublisher<User, Error> in
                // フォロー解除成功後、最新のユーザー情報を取得
                guard let self = self else {
                    return Fail(error: NSError(domain: "", code: -1, userInfo: nil))
                        .eraseToAnyPublisher()
                }
                return self.userService.getUser(uid: currentUser.id)
                    .compactMap { $0 }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        print(
                            "❌ [ListHeartBeatsViewModel] unfollowUser: エラー - \(error.localizedDescription)"
                        )
                        self?.errorMessage = "フォロー解除に失敗しました: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] updatedUser in
                    print("✅ [ListHeartBeatsViewModel] unfollowUser: 成功")
                    // AuthenticationManagerのcurrentUserを更新
                    self?.authenticationManager.currentUser = updatedUser
                    // ローカルのリストから削除
                    self?.followingUsersWithHeartbeats.removeAll { $0.user.id == userId }
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func setupBindings() {
        Publishers.CombineLatest3(
            authenticationManager.$isAuthenticated,
            authenticationManager.$isLoading,
            authenticationManager.$currentUser
        )
        .removeDuplicates { prev, current in
            prev.0 == current.0 && prev.1 == current.1 && prev.2?.id == current.2?.id
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isAuthenticated, isLoading, currentUser in
            guard !isLoading else { return }

            if isAuthenticated, currentUser != nil {
                self?.loadFollowingUsersWithHeartbeatsIfNeeded()
            } else {
                self?.clearData()
            }
        }
        .store(in: &cancellables)
    }

    private func clearData() {
        followingUsersWithHeartbeats = []
        errorMessage = nil
        isLoading = false
    }

    private func loadFollowingUsersWithHeartbeatsIfNeeded() {
        // 既にデータがある場合は読み込みをスキップ
        guard followingUsersWithHeartbeats.isEmpty else { return }

        loadFollowingUsersWithHeartbeats()
    }

    func loadFollowingUsersWithHeartbeats() {
        guard let currentUser = authenticationManager.currentUser else {
            isLoading = false
            return
        }

        isLoading = true

        userService.getFollowingUsers(followingUserIds: currentUser.followingUserIds)
            .flatMap { [weak self] users -> AnyPublisher<[UserWithHeartbeat], Error> in
                self?.loadHeartbeatsForUsers(users)
                    ?? Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.handleLoadCompletion(completion)
                },
                receiveValue: { [weak self] usersWithHeartbeats in
                    self?.handleLoadSuccess(usersWithHeartbeats)
                }
            )
            .store(in: &cancellables)
    }

    private func loadHeartbeatsForUsers(_ users: [User]) -> AnyPublisher<[UserWithHeartbeat], Error>
    {
        guard !users.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let heartbeatPublishers = users.map { user in
            heartbeatService.getHeartbeatOnce(userId: user.id)
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

    private func handleLoadCompletion(_ completion: Subscribers.Completion<Error>) {
        isLoading = false
        if case let .failure(error) = completion {
            errorMessage = error.localizedDescription
        }
    }

    private func handleLoadSuccess(_ usersWithHeartbeats: [UserWithHeartbeat]) {
        followingUsersWithHeartbeats = sortUsers(usersWithHeartbeats, by: currentSortOption)
    }

    private func applySorting() {
        followingUsersWithHeartbeats = sortUsers(
            followingUsersWithHeartbeats, by: currentSortOption)
    }

    private func sortUsers(_ users: [UserWithHeartbeat], by sortOption: SortOption)
        -> [UserWithHeartbeat]
    {
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

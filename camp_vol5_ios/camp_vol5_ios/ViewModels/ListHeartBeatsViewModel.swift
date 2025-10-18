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
class ListHeartBeatsViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published var followingUsersWithHeartbeats: [UserWithHeartbeat] = []
    @Published var currentSortOption: SortOption = .name

    // MARK: - Private Properties

    private var authenticationManager: AuthenticationManager

    // MARK: - Dependencies

    private let userService: UserServiceProtocol
    private let heartbeatService: HeartbeatServiceProtocol
    private let followerRepository: FollowerRepositoryProtocol

    // MARK: - Computed Properties

    var hasFollowingUsers: Bool {
        !followingUsersWithHeartbeats.isEmpty
    }

    var isAuthenticated: Bool {
        authenticationManager.isAuthenticated
    }

    // MARK: - Initialization

    init(
        authenticationManager: AuthenticationManager = AuthenticationManager(),
        userService: UserServiceProtocol = UserService.shared,
        heartbeatService: HeartbeatServiceProtocol = HeartbeatService.shared,
        followerRepository: FollowerRepositoryProtocol = FirestoreFollowerRepository()
    ) {
        self.authenticationManager = authenticationManager
        self.userService = userService
        self.heartbeatService = heartbeatService
        self.followerRepository = followerRepository
        super.init()
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

        setLoading(true)

        // 最新のユーザー情報をFirestoreから取得してからフォローユーザーリストを更新
        userService.getUser(uid: currentUserId)
            .compactMap { $0 }
            .handleErrors(on: self, defaultValue: nil)
            .sink { [weak self] updatedUser in
                guard let self = self, let updatedUser = updatedUser else {
                    self?.setLoading(false)
                    return
                }
                print("✅ [ListHeartBeatsViewModel] refreshData: ユーザー情報取得成功")
                // AuthenticationManagerのcurrentUserを更新
                self.authenticationManager.currentUser = updatedUser
                // フォローユーザーリストを再読み込み
                self.loadFollowingUsersWithHeartbeats()
            }
            .store(in: &cancellables)
    }

    func changeSortOption(_ sortOption: SortOption) {
        currentSortOption = sortOption
        applySorting()
    }

    func unfollowUser(userId: String) {
        print("📤 [ListHeartBeatsViewModel] unfollowUser: 開始 - userId: \(userId)")

        guard let currentUser = authenticationManager.currentUser else {
            print("⚠️ [ListHeartBeatsViewModel] unfollowUser: currentUserがnil")
            handleError(
                NSError(
                    domain: "ListHeartBeatsViewModel",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "ユーザー情報が取得できません"]
                ))
            return
        }

        userService.unfollowUser(currentUserId: currentUser.id, targetUserId: userId)
            .flatMap { [weak self] _ -> AnyPublisher<User?, Error> in
                // フォロー解除成功後、最新のユーザー情報を取得
                guard let self = self else {
                    return Fail(
                        error: NSError(
                            domain: "ListHeartBeatsViewModel",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "サービスが利用できません"]
                        )
                    )
                    .eraseToAnyPublisher()
                }
                return self.userService.getUser(uid: currentUser.id)
                    .eraseToAnyPublisher()
            }
            .handleErrors(on: self)
            .compactMap { $0 }
            .sink { [weak self] updatedUser in
                print("✅ [ListHeartBeatsViewModel] unfollowUser: 成功")
                // AuthenticationManagerのcurrentUserを更新
                self?.authenticationManager.currentUser = updatedUser
                // ローカルのリストから削除
                self?.followingUsersWithHeartbeats.removeAll { $0.user.id == userId }
            }
            .store(in: &cancellables)
    }

    func toggleNotificationSetting(for userId: String, enabled: Bool) {
        print(
            "🔔 [ListHeartBeatsViewModel] toggleNotificationSetting: 開始 - userId: \(userId), enabled: \(enabled)"
        )

        guard let currentUser = authenticationManager.currentUser else {
            print("⚠️ [ListHeartBeatsViewModel] toggleNotificationSetting: currentUserがnil")
            handleError(
                NSError(
                    domain: "ListHeartBeatsViewModel",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "ユーザー情報が取得できません"]
                ))
            return
        }

        // ローカルの状態を即座に更新（楽観的更新）
        if let index = followingUsersWithHeartbeats.firstIndex(where: { $0.user.id == userId }) {
            followingUsersWithHeartbeats[index] = UserWithHeartbeat(
                user: followingUsersWithHeartbeats[index].user,
                heartbeat: followingUsersWithHeartbeats[index].heartbeat,
                notificationEnabled: enabled
            )
        }

        userService.updateFollowingNotificationSetting(
            currentUserId: currentUser.id,
            targetUserId: userId,
            enabled: enabled
        )
        .handleErrors(on: self)
        .sink { [weak self] _ in
            print(
                "✅ [ListHeartBeatsViewModel] toggleNotificationSetting: 成功 - userId: \(userId)"
            )
        }
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
        .sink { [weak self] isAuthenticated, isAuthLoading, currentUser in
            guard !isAuthLoading else { return }

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
        setLoading(false)
    }

    private func loadFollowingUsersWithHeartbeatsIfNeeded() {
        // 既にデータがある場合は読み込みをスキップ
        guard followingUsersWithHeartbeats.isEmpty else { return }

        loadFollowingUsersWithHeartbeats()
    }

    func loadFollowingUsersWithHeartbeats() {
        guard let currentUser = authenticationManager.currentUser else {
            setLoading(false)
            return
        }

        setLoading(true)

        userService.getFollowingUsers(userId: currentUser.id)
            .flatMap { [weak self] users -> AnyPublisher<[UserWithHeartbeat], Error> in
                self?.loadHeartbeatsForUsers(users)
                    ?? Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .handleErrors(on: self, defaultValue: [])
            .sink { [weak self] usersWithHeartbeats in
                self?.handleLoadSuccess(usersWithHeartbeats)
            }
            .store(in: &cancellables)
    }

    private func loadHeartbeatsForUsers(_ users: [User]) -> AnyPublisher<[UserWithHeartbeat], Error>
    {
        guard !users.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        guard let currentUserId = authenticationManager.currentUserId else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let userPublishers = users.map { user in
            // ハートビート情報とフォロワー情報を並行して取得
            Publishers.Zip(
                heartbeatService.getHeartbeatOnce(userId: user.id)
                    .catch { _ in Just(nil).setFailureType(to: Error.self) },
                followerRepository.fetchFollower(userId: user.id, followerId: currentUserId)
                    .catch { _ in Just(nil).setFailureType(to: Error.self) }
            )
            .map { heartbeat, follower in
                UserWithHeartbeat(
                    user: user,
                    heartbeat: heartbeat,
                    notificationEnabled: follower?.notificationEnabled ?? true  // デフォルトはtrue
                )
            }
            .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(userPublishers)
            .collect()
            .eraseToAnyPublisher()
    }

    private func handleLoadSuccess(_ usersWithHeartbeats: [UserWithHeartbeat]) {
        followingUsersWithHeartbeats = sortUsers(usersWithHeartbeats, by: currentSortOption)
        setLoading(false)
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
    var notificationEnabled: Bool  // フォロー先ユーザーからの通知設定

    func hash(into hasher: inout Hasher) {
        hasher.combine(user.id)
        hasher.combine(user.name)
        hasher.combine(heartbeat?.bpm)
        hasher.combine(notificationEnabled)
    }

    static func == (lhs: UserWithHeartbeat, rhs: UserWithHeartbeat) -> Bool {
        return lhs.user.id == rhs.user.id && lhs.notificationEnabled == rhs.notificationEnabled
    }
}

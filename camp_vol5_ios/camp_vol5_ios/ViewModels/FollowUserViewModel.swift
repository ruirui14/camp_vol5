// ViewModels/FollowUserViewModel.swift
// フォローユーザー画面のビューモデル - MVVM設計パターンに従いビジネスロジックを集約
// ユーザー検索、フォロー処理、認証状態管理を責務として持つ

import Combine
import Foundation

@MainActor
class FollowUserViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var scannedUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isFollowingUser: Bool = false
    @Published var shouldDismiss: Bool = false

    // MARK: - Private Properties
    private var authenticationManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies
    private let userService: UserService

    // MARK: - Computed Properties
    var canFollowUser: Bool {
        guard let user = scannedUser else { return false }
        guard !isFollowingUser else { return false }

        // 自分自身をフォローできない
        if let currentUserId = authenticationManager.currentUserId {
            return user.id != currentUserId
        }

        return true
    }

    // MARK: - Initialization
    init(
        authenticationManager: AuthenticationManager,
        userService: UserService = UserService.shared
    ) {
        self.authenticationManager = authenticationManager
        self.userService = userService
    }

    func updateAuthenticationManager(_ authenticationManager: AuthenticationManager) {
        print("🔧 [FollowUserViewModel] updateAuthenticationManager: 開始")
        self.authenticationManager = authenticationManager
        print("🔧 [FollowUserViewModel] updateAuthenticationManager: 完了")
    }

    // MARK: - Public Methods

    func searchUserByInviteCode(_ code: String) {
        print("🔍 [FollowUserViewModel] searchUserByInviteCode: 開始 - code: \(code)")

        guard validateInviteCode(code) else { return }

        isLoading = true
        scannedUser = nil

        userService.findUserByInviteCode(code)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.handleSearchCompletion(completion)
                },
                receiveValue: { [weak self] user in
                    self?.handleSearchResult(user)
                }
            )
            .store(in: &cancellables)
    }

    func handleQRCodeScan(_ code: String) {
        print("📷 [FollowUserViewModel] handleQRCodeScan: 開始 - code: \(code)")
        clearError()
        searchUserByInviteCode(code)
        print("📷 [FollowUserViewModel] handleQRCodeScan: 完了")
    }

    func followUser() {
        print("💖 [FollowUserViewModel] followUser: 開始")

        guard let user = scannedUser else {
            handleError("ユーザー情報が取得できません")
            return
        }

        guard canFollowUser else {
            if isFollowingUser {
                handleError("既にフォロー済みです")
            } else {
                handleError("自分自身をフォローすることはできません")
            }
            return
        }

        guard let currentUser = authenticationManager.currentUser else {
            handleError("ユーザー情報が取得できません")
            return
        }

        followUserWithFirebase(currentUser: currentUser, targetUser: user)

        print("💖 [FollowUserViewModel] followUser: 完了")
    }

    func unfollowUser() {
        print("💔 [FollowUserViewModel] unfollowUser: 開始")

        guard let user = scannedUser else {
            handleError("ユーザー情報が取得できません")
            return
        }

        guard let currentUser = authenticationManager.currentUser else {
            handleError("ユーザー情報が取得できません")
            return
        }

        unfollowUserWithFirebase(currentUser: currentUser, targetUser: user)

        print("💔 [FollowUserViewModel] unfollowUser: 完了")
    }

    func clearInput() {
        print("🧹 [FollowUserViewModel] clearInput: 開始")
        scannedUser = nil
        isFollowingUser = false
        shouldDismiss = false
        clearError()
        clearSuccessMessage()
        print("🧹 [FollowUserViewModel] clearInput: 完了")
    }

    func clearError() {
        print("🧹 [FollowUserViewModel] clearError: 実行")
        errorMessage = nil
    }

    func clearSuccessMessage() {
        print("🧹 [FollowUserViewModel] clearSuccessMessage: 実行")
        successMessage = nil
    }

    // MARK: - Private Methods

    private func validateInviteCode(_ code: String) -> Bool {
        guard !code.isEmpty else {
            handleError("招待コードを入力してください")
            return false
        }
        return true
    }

    private func handleSearchCompletion(_ completion: Subscribers.Completion<Error>) {
        isLoading = false
        if case let .failure(error) = completion {
            print(
                "❌ [FollowUserViewModel] searchUserByInviteCode: エラー - \(error.localizedDescription)"
            )
            handleError(error.localizedDescription)
        }
        print("🔍 [FollowUserViewModel] searchUserByInviteCode: 完了")
    }

    private func handleSearchResult(_ user: User?) {
        if let user = user {
            print("✅ [FollowUserViewModel] searchUserByInviteCode: ユーザー発見 - \(user.name)")
            // 少し遅延を入れてからユーザー情報を設定
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.scannedUser = user
                self.checkIfAlreadyFollowing(user)
            }
        } else {
            print("❌ [FollowUserViewModel] searchUserByInviteCode: ユーザーが見つからない")
            handleError("ユーザーが見つかりません")
        }
    }

    private func handleError(_ message: String) {
        print("❌ [FollowUserViewModel] エラー: \(message)")
        errorMessage = message
    }

    private func checkIfAlreadyFollowing(_ user: User) {
        print("👤 [FollowUserViewModel] checkIfAlreadyFollowing: 開始 - user: \(user.name)")

        guard let currentUserId = authenticationManager.currentUserId else {
            print("⚠️ [FollowUserViewModel] checkIfAlreadyFollowing: currentUserIdがnil")
            isFollowingUser = false
            return
        }

        checkFollowingStatusWithFirebase(userId: currentUserId, targetUserId: user.id)
    }

    private func checkFollowingStatusWithFirebase(userId: String, targetUserId: String) {
        userService.getUser(uid: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.isFollowingUser = false
                    }
                },
                receiveValue: { [weak self] currentUser in
                    if let currentUser = currentUser {
                        let isFollowing = currentUser.followingUserIds.contains(targetUserId)
                        self?.isFollowingUser = isFollowing
                        print(
                            "✅ [FollowUserViewModel] checkIfAlreadyFollowing: Firebase確認完了 - isFollowing: \(isFollowing)"
                        )
                    } else {
                        self?.isFollowingUser = false
                        print("⚠️ [FollowUserViewModel] checkIfAlreadyFollowing: currentUserがnil")
                    }
                    print("👤 [FollowUserViewModel] checkIfAlreadyFollowing: 完了")
                }
            )
            .store(in: &cancellables)
    }

    private func followUserWithFirebase(currentUser: User, targetUser: User) {
        print("🔥 [FollowUserViewModel] followUserWithFirebase: 開始 - target: \(targetUser.name)")
        isLoading = true

        userService.followUser(currentUser: currentUser, targetUserId: targetUser.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.handleFollowCompletion(completion, targetUserName: targetUser.name)
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func unfollowUserWithFirebase(currentUser: User, targetUser: User) {
        print(
            "🔥 [FollowUserViewModel] unfollowUserWithFirebase: 開始 - target: \(targetUser.name)")
        isLoading = true

        userService.unfollowUser(currentUser: currentUser, targetUserId: targetUser.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.handleUnfollowCompletion(completion, targetUserName: targetUser.name)
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func handleFollowCompletion(
        _ completion: Subscribers.Completion<Error>, targetUserName: String
    ) {
        isLoading = false
        if case let .failure(error) = completion {
            print(
                "❌ [FollowUserViewModel] followUserWithFirebase: エラー - \(error.localizedDescription)"
            )
            handleError(error.localizedDescription)
        } else {
            handleFollowSuccess(targetUserName: targetUserName)
            updateCurrentUserAfterFollow()
        }
        print("🔥 [FollowUserViewModel] followUserWithFirebase: 完了")
    }

    private func handleUnfollowCompletion(
        _ completion: Subscribers.Completion<Error>, targetUserName: String
    ) {
        isLoading = false
        if case let .failure(error) = completion {
            print(
                "❌ [FollowUserViewModel] unfollowUserWithFirebase: エラー - \(error.localizedDescription)"
            )
            handleError(error.localizedDescription)
        } else {
            handleUnfollowSuccess(targetUserName: targetUserName)
            updateCurrentUserAfterFollow()
        }
        print("🔥 [FollowUserViewModel] unfollowUserWithFirebase: 完了")
    }

    private func handleFollowSuccess(targetUserName: String) {
        print("✅ [FollowUserViewModel] フォロー成功")
        isFollowingUser = true
        successMessage = "\(targetUserName)さんをフォローしました"
    }

    private func handleUnfollowSuccess(targetUserName: String) {
        print("✅ [FollowUserViewModel] フォロー解除成功")
        isFollowingUser = false
        successMessage = "\(targetUserName)さんのフォローを解除しました"
    }

    private func updateCurrentUserAfterFollow() {
        if let currentUserId = authenticationManager.currentUserId {
            authenticationManager.loadCurrentUser(uid: currentUserId)
        }
    }
}

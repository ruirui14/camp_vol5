// ViewModels/QRCodeScannerViewModel.swift
// QRコードスキャナー画面のビューモデル - MVVM設計パターンに従いビジネスロジックを集約
// ユーザー検索、フォロー処理、認証状態管理を責務として持つ

import Combine
import Foundation

@MainActor
class QRCodeScannerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var scannedUser: User?
    @Published var inviteCode: String = ""
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
    private let localFollowService: LocalFollowService

    // MARK: - Computed Properties
    var canFollowUser: Bool {
        guard let user = scannedUser else { return false }
        guard !isFollowingUser else { return false }

        // 認証済みの場合は自分自身をフォローできない
        if authenticationManager.isAuthenticated,
           let currentUserId = authenticationManager.currentUserId {
            return user.id != currentUserId
        }

        return true
    }

    // MARK: - Initialization
    init(
        authenticationManager: AuthenticationManager,
        userService: UserService = UserService.shared,
        localFollowService: LocalFollowService = LocalFollowService.shared
    ) {
        self.authenticationManager = authenticationManager
        self.userService = userService
        self.localFollowService = localFollowService
    }

    func updateAuthenticationManager(_ authenticationManager: AuthenticationManager) {
        print("🔧 [QRCodeScannerViewModel] updateAuthenticationManager: 開始")
        self.authenticationManager = authenticationManager
        print("🔧 [QRCodeScannerViewModel] updateAuthenticationManager: 完了")
    }

    // MARK: - Public Methods

    func searchUserByInviteCode(_ code: String) {
        print("🔍 [QRCodeScannerViewModel] searchUserByInviteCode: 開始 - code: \(code)")

        guard validateInviteCode(code) else { return }

        inviteCode = code
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
        print("📷 [QRCodeScannerViewModel] handleQRCodeScan: 開始 - code: \(code)")
        clearError()
        searchUserByInviteCode(code)
        print("📷 [QRCodeScannerViewModel] handleQRCodeScan: 完了")
    }

    func followUser() {
        print("💖 [QRCodeScannerViewModel] followUser: 開始")

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

        if authenticationManager.isAuthenticated,
           let currentUser = authenticationManager.currentUser {
            followUserWithFirebase(currentUser: currentUser, targetUser: user)
        } else {
            followUserLocally(user: user)
        }

        print("💖 [QRCodeScannerViewModel] followUser: 完了")
    }

    func unfollowUser() {
        print("💔 [QRCodeScannerViewModel] unfollowUser: 開始")

        guard let user = scannedUser else {
            handleError("ユーザー情報が取得できません")
            return
        }

        if authenticationManager.isAuthenticated,
           let currentUser = authenticationManager.currentUser {
            unfollowUserWithFirebase(currentUser: currentUser, targetUser: user)
        } else {
            unfollowUserLocally(user: user)
        }

        print("💔 [QRCodeScannerViewModel] unfollowUser: 完了")
    }

    func clearInput() {
        print("🧹 [QRCodeScannerViewModel] clearInput: 開始")
        inviteCode = ""
        scannedUser = nil
        isFollowingUser = false
        shouldDismiss = false
        clearError()
        clearSuccessMessage()
        print("🧹 [QRCodeScannerViewModel] clearInput: 完了")
    }

    func clearError() {
        print("🧹 [QRCodeScannerViewModel] clearError: 実行")
        errorMessage = nil
    }

    func clearSuccessMessage() {
        print("🧹 [QRCodeScannerViewModel] clearSuccessMessage: 実行")
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
            print("❌ [QRCodeScannerViewModel] searchUserByInviteCode: エラー - \(error.localizedDescription)")
            handleError(error.localizedDescription)
        }
        print("🔍 [QRCodeScannerViewModel] searchUserByInviteCode: 完了")
    }

    private func handleSearchResult(_ user: User?) {
        if let user = user {
            print("✅ [QRCodeScannerViewModel] searchUserByInviteCode: ユーザー発見 - \(user.name)")
            // 少し遅延を入れてからユーザー情報を設定
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.scannedUser = user
                self.checkIfAlreadyFollowing(user)
            }
        } else {
            print("❌ [QRCodeScannerViewModel] searchUserByInviteCode: ユーザーが見つからない")
            handleError("ユーザーが見つかりません")
        }
    }

    private func handleError(_ message: String) {
        print("❌ [QRCodeScannerViewModel] エラー: \(message)")
        errorMessage = message
    }

    private func checkIfAlreadyFollowing(_ user: User) {
        print("👤 [QRCodeScannerViewModel] checkIfAlreadyFollowing: 開始 - user: \(user.name)")

        if authenticationManager.isAuthenticated,
           let currentUserId = authenticationManager.currentUserId {
            checkFollowingStatusWithFirebase(userId: currentUserId, targetUserId: user.id)
        } else {
            checkFollowingStatusLocally(targetUserId: user.id)
        }
    }

    private func checkFollowingStatusWithFirebase(userId: String, targetUserId: String) {
        userService.getUser(uid: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(_) = completion {
                        self?.isFollowingUser = false
                    }
                },
                receiveValue: { [weak self] currentUser in
                    if let currentUser = currentUser {
                        let isFollowing = currentUser.followingUserIds.contains(targetUserId)
                        self?.isFollowingUser = isFollowing
                        print("✅ [QRCodeScannerViewModel] checkIfAlreadyFollowing: Firebase確認完了 - isFollowing: \(isFollowing)")
                    } else {
                        self?.isFollowingUser = false
                        print("⚠️ [QRCodeScannerViewModel] checkIfAlreadyFollowing: currentUserがnil")
                    }
                    print("👤 [QRCodeScannerViewModel] checkIfAlreadyFollowing: 完了")
                }
            )
            .store(in: &cancellables)
    }

    private func checkFollowingStatusLocally(targetUserId: String) {
        let isFollowing = localFollowService.isFollowing(targetUserId)
        isFollowingUser = isFollowing
        print("✅ [QRCodeScannerViewModel] checkIfAlreadyFollowing: ローカル確認完了 - isFollowing: \(isFollowing)")
        print("👤 [QRCodeScannerViewModel] checkIfAlreadyFollowing: 完了")
    }


    private func followUserWithFirebase(currentUser: User, targetUser: User) {
        print("🔥 [QRCodeScannerViewModel] followUserWithFirebase: 開始 - target: \(targetUser.name)")
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

    private func followUserLocally(user: User) {
        print("📱 [QRCodeScannerViewModel] followUserLocally: 開始 - user: \(user.name)")
        localFollowService.followUser(user.id)
        handleFollowSuccess(targetUserName: user.name)
        print("📱 [QRCodeScannerViewModel] followUserLocally: 完了")
    }


    private func unfollowUserWithFirebase(currentUser: User, targetUser: User) {
        print("🔥 [QRCodeScannerViewModel] unfollowUserWithFirebase: 開始 - target: \(targetUser.name)")
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

    private func unfollowUserLocally(user: User) {
        print("📱 [QRCodeScannerViewModel] unfollowUserLocally: 開始 - user: \(user.name)")
        localFollowService.unfollowUser(user.id)
        handleUnfollowSuccess(targetUserName: user.name)
        print("📱 [QRCodeScannerViewModel] unfollowUserLocally: 完了")
    }

    private func handleFollowCompletion(_ completion: Subscribers.Completion<Error>, targetUserName: String) {
        isLoading = false
        if case let .failure(error) = completion {
            print("❌ [QRCodeScannerViewModel] followUserWithFirebase: エラー - \(error.localizedDescription)")
            handleError(error.localizedDescription)
        } else {
            handleFollowSuccess(targetUserName: targetUserName)
            updateCurrentUserAfterFollow()
        }
        print("🔥 [QRCodeScannerViewModel] followUserWithFirebase: 完了")
    }

    private func handleUnfollowCompletion(_ completion: Subscribers.Completion<Error>, targetUserName: String) {
        isLoading = false
        if case let .failure(error) = completion {
            print("❌ [QRCodeScannerViewModel] unfollowUserWithFirebase: エラー - \(error.localizedDescription)")
            handleError(error.localizedDescription)
        } else {
            handleUnfollowSuccess(targetUserName: targetUserName)
            updateCurrentUserAfterFollow()
        }
        print("🔥 [QRCodeScannerViewModel] unfollowUserWithFirebase: 完了")
    }

    private func handleFollowSuccess(targetUserName: String) {
        print("✅ [QRCodeScannerViewModel] フォロー成功")
        isFollowingUser = true
        successMessage = "\(targetUserName)さんをフォローしました"
        scheduleAutoClose()
    }

    private func handleUnfollowSuccess(targetUserName: String) {
        print("✅ [QRCodeScannerViewModel] フォロー解除成功")
        isFollowingUser = false
        successMessage = "\(targetUserName)さんのフォローを解除しました"
    }

    private func updateCurrentUserAfterFollow() {
        if let currentUserId = authenticationManager.currentUserId {
            authenticationManager.loadCurrentUser(uid: currentUserId)
        }
    }

    private func scheduleAutoClose() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.shouldDismiss = true
        }
    }
}

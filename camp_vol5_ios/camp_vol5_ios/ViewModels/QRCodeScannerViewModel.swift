// ViewModels/QRCodeScannerViewModel.swift
import Combine
import Foundation

class QRCodeScannerViewModel: ObservableObject {
    @Published var scannedUser: User?
    @Published var inviteCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isFollowingUser: Bool = false
    @Published var shouldDismiss: Bool = false

    private var authenticationManager: AuthenticationManager
    private var localFollowService = LocalFollowService.shared
    private var cancellables = Set<AnyCancellable>()

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
    }

    func updateAuthenticationManager(_ authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
    }

    // 招待コードまたはQRコードからユーザー情報を取得
    func searchUserByInviteCode(_ code: String) {
        guard !code.isEmpty else {
            errorMessage = "招待コードを入力してください"
            return
        }

        inviteCode = code
        isLoading = true
        scannedUser = nil
        // shouldDismissの設定を削除（初期化時のfalseのままにする）

        UserService.shared.findUserByInviteCode(code)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    if let user = user {
                        // 少し遅延を入れてからユーザー情報を設定
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self?.scannedUser = user
                            self?.checkIfAlreadyFollowing(user)
                        }
                    } else {
                        self?.errorMessage = "ユーザーが見つかりません"
                    }
                }
            )
            .store(in: &cancellables)
    }

    // 既にフォロー済みかチェック
    private func checkIfAlreadyFollowing(_ user: User) {
        if authenticationManager.isAuthenticated, let currentUserId = authenticationManager.currentUserId {
            // 認証済みの場合はFirebaseでチェック
            UserService.shared.getUser(uid: currentUserId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case let .failure(error) = completion {
                            // エラーが発生してもフォロー状態はfalseとして継続
                            self?.isFollowingUser = false
                        }
                    },
                    receiveValue: { [weak self] currentUser in
                        if let currentUser = currentUser {
                            self?.isFollowingUser = currentUser.followingUserIds
                                .contains(user.id)
                        } else {
                            self?.isFollowingUser = false
                        }
                    }
                )
                .store(in: &cancellables)
        } else {
            // 未認証の場合はローカルでチェック
            isFollowingUser = localFollowService.isFollowing(user.id)
        }
    }

    // ユーザーをフォロー
    func followUser() {
        guard let user = scannedUser else {
            errorMessage = "ユーザー情報が取得できません"
            return
        }

        // 認証済みの場合は自分自身フォローチェック
        if authenticationManager.isAuthenticated, let currentUserId = authenticationManager.currentUserId {
            if user.id == currentUserId {
                errorMessage = "自分自身をフォローすることはできません"
                return
            }
        }

        // 既にフォロー済み
        if isFollowingUser {
            errorMessage = "既にフォロー済みです"
            return
        }

        if authenticationManager.isAuthenticated, let currentUser = authenticationManager.currentUser {
            // 認証済みの場合はFirebaseでフォロー
            followUserWithFirebase(currentUser: currentUser, targetUser: user)
        } else {
            // 未認証の場合はローカルでフォロー
            followUserLocally(user: user)
        }
    }

    private func followUserWithFirebase(currentUser: User, targetUser: User) {
        isLoading = true

        UserService.shared.followUser(currentUser: currentUser, targetUserId: targetUser.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        self?.isFollowingUser = true
                        self?.successMessage = "\(targetUser.name)さんをフォローしました"

                        // フォロー成功後、現在のユーザー情報を更新
                        if let currentUserId = self?.authenticationManager.currentUserId {
                            self?.authenticationManager.loadCurrentUser(
                                uid: currentUserId
                            )
                        }

                        // フォロー成功後、2秒後にページを閉じる
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self?.shouldDismiss = true
                        }
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func followUserLocally(user: User) {
        localFollowService.followUser(user.id)
        isFollowingUser = true
        successMessage = "\(user.name)さんをフォローしました"

        // フォロー成功後、2秒後にページを閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.shouldDismiss = true
        }
    }

    // フォロー解除
    func unfollowUser() {
        guard let user = scannedUser else { return }

        if authenticationManager.isAuthenticated, let currentUser = authenticationManager.currentUser {
            // 認証済みの場合はFirebaseでフォロー解除
            unfollowUserWithFirebase(currentUser: currentUser, targetUser: user)
        } else {
            // 未認証の場合はローカルでフォロー解除
            unfollowUserLocally(user: user)
        }
    }

    private func unfollowUserWithFirebase(currentUser: User, targetUser: User) {
        isLoading = true

        UserService.shared.unfollowUser(currentUser: currentUser, targetUserId: targetUser.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        self?.isFollowingUser = false
                        self?.successMessage = "\(targetUser.name)さんのフォローを解除しました"

                        // フォロー解除後、現在のユーザー情報を更新
                        if let currentUserId = self?.authenticationManager.currentUserId {
                            self?.authenticationManager.loadCurrentUser(
                                uid: currentUserId
                            )
                        }
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func unfollowUserLocally(user: User) {
        localFollowService.unfollowUser(user.id)
        isFollowingUser = false
        successMessage = "\(user.name)さんのフォローを解除しました"
    }

    // QRコードスキャン結果を処理
    func handleQRCodeScan(_ code: String) {
        // エラーをクリアしてからユーザー検索を開始
        errorMessage = nil
        searchUserByInviteCode(code)
    }

    // 入力をクリア
    func clearInput() {
        inviteCode = ""
        scannedUser = nil
        isFollowingUser = false
        shouldDismiss = false
        clearError()
        clearSuccessMessage()
    }

    func clearError() {
        errorMessage = nil
    }

    func clearSuccessMessage() {
        successMessage = nil
    }
}

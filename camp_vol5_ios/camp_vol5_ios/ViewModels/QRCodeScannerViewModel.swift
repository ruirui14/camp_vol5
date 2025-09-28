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
        print("🔧 [QRCodeScannerViewModel] updateAuthenticationManager: 開始")
        self.authenticationManager = authenticationManager
        print("🔧 [QRCodeScannerViewModel] updateAuthenticationManager: 完了")
    }

    // 招待コードまたはQRコードからユーザー情報を取得
    func searchUserByInviteCode(_ code: String) {
        print("🔍 [QRCodeScannerViewModel] searchUserByInviteCode: 開始 - code: \(code)")
        guard !code.isEmpty else {
            print("❌ [QRCodeScannerViewModel] searchUserByInviteCode: エラー - コードが空")
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
                        print("❌ [QRCodeScannerViewModel] searchUserByInviteCode: エラー - \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    }
                    print("🔍 [QRCodeScannerViewModel] searchUserByInviteCode: 完了")
                },
                receiveValue: { [weak self] user in
                    if let user = user {
                        print("✅ [QRCodeScannerViewModel] searchUserByInviteCode: ユーザー発見 - \(user.name)")
                        // 少し遅延を入れてからユーザー情報を設定
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self?.scannedUser = user
                            self?.checkIfAlreadyFollowing(user)
                        }
                    } else {
                        print("❌ [QRCodeScannerViewModel] searchUserByInviteCode: ユーザーが見つからない")
                        self?.errorMessage = "ユーザーが見つかりません"
                    }
                }
            )
            .store(in: &cancellables)
    }

    // 既にフォロー済みかチェック
    private func checkIfAlreadyFollowing(_ user: User) {
        print("👤 [QRCodeScannerViewModel] checkIfAlreadyFollowing: 開始 - user: \(user.name)")
        if authenticationManager.isAuthenticated,
            let currentUserId = authenticationManager.currentUserId
        {
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
                            let isFollowing = currentUser.followingUserIds.contains(user.id)
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
        } else {
            // 未認証の場合はローカルでチェック
            let isFollowing = localFollowService.isFollowing(user.id)
            isFollowingUser = isFollowing
            print("✅ [QRCodeScannerViewModel] checkIfAlreadyFollowing: ローカル確認完了 - isFollowing: \(isFollowing)")
            print("👤 [QRCodeScannerViewModel] checkIfAlreadyFollowing: 完了")
        }
    }

    // ユーザーをフォロー
    func followUser() {
        print("💖 [QRCodeScannerViewModel] followUser: 開始")
        guard let user = scannedUser else {
            print("❌ [QRCodeScannerViewModel] followUser: エラー - scannedUserがnil")
            errorMessage = "ユーザー情報が取得できません"
            return
        }

        // 認証済みの場合は自分自身フォローチェック
        if authenticationManager.isAuthenticated,
            let currentUserId = authenticationManager.currentUserId
        {
            if user.id == currentUserId {
                print("❌ [QRCodeScannerViewModel] followUser: エラー - 自分自身をフォロー")
                errorMessage = "自分自身をフォローすることはできません"
                return
            }
        }

        // 既にフォロー済み
        if isFollowingUser {
            print("❌ [QRCodeScannerViewModel] followUser: エラー - 既にフォロー済み")
            errorMessage = "既にフォロー済みです"
            return
        }

        if authenticationManager.isAuthenticated,
            let currentUser = authenticationManager.currentUser
        {
            // 認証済みの場合はFirebaseでフォロー
            print("🔥 [QRCodeScannerViewModel] followUser: Firebaseでフォロー処理")
            followUserWithFirebase(currentUser: currentUser, targetUser: user)
        } else {
            // 未認証の場合はローカルでフォロー
            print("📱 [QRCodeScannerViewModel] followUser: ローカルでフォロー処理")
            followUserLocally(user: user)
        }
        print("💖 [QRCodeScannerViewModel] followUser: 完了")
    }

    private func followUserWithFirebase(currentUser: User, targetUser: User) {
        print("🔥 [QRCodeScannerViewModel] followUserWithFirebase: 開始 - target: \(targetUser.name)")
        isLoading = true

        UserService.shared.followUser(currentUser: currentUser, targetUserId: targetUser.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(error) = completion {
                        print("❌ [QRCodeScannerViewModel] followUserWithFirebase: エラー - \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    } else {
                        print("✅ [QRCodeScannerViewModel] followUserWithFirebase: 成功")
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
                    print("🔥 [QRCodeScannerViewModel] followUserWithFirebase: 完了")
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func followUserLocally(user: User) {
        print("📱 [QRCodeScannerViewModel] followUserLocally: 開始 - user: \(user.name)")
        localFollowService.followUser(user.id)
        isFollowingUser = true
        successMessage = "\(user.name)さんをフォローしました"
        print("✅ [QRCodeScannerViewModel] followUserLocally: 成功")

        // フォロー成功後、2秒後にページを閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.shouldDismiss = true
        }
        print("📱 [QRCodeScannerViewModel] followUserLocally: 完了")
    }

    // フォロー解除
    func unfollowUser() {
        print("💔 [QRCodeScannerViewModel] unfollowUser: 開始")
        guard let user = scannedUser else {
            print("❌ [QRCodeScannerViewModel] unfollowUser: エラー - scannedUserがnil")
            return
        }

        if authenticationManager.isAuthenticated,
            let currentUser = authenticationManager.currentUser
        {
            // 認証済みの場合はFirebaseでフォロー解除
            print("🔥 [QRCodeScannerViewModel] unfollowUser: Firebaseでフォロー解除処理")
            unfollowUserWithFirebase(currentUser: currentUser, targetUser: user)
        } else {
            // 未認証の場合はローカルでフォロー解除
            print("📱 [QRCodeScannerViewModel] unfollowUser: ローカルでフォロー解除処理")
            unfollowUserLocally(user: user)
        }
        print("💔 [QRCodeScannerViewModel] unfollowUser: 完了")
    }

    private func unfollowUserWithFirebase(currentUser: User, targetUser: User) {
        print("🔥 [QRCodeScannerViewModel] unfollowUserWithFirebase: 開始 - target: \(targetUser.name)")
        isLoading = true

        UserService.shared.unfollowUser(currentUser: currentUser, targetUserId: targetUser.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(error) = completion {
                        print("❌ [QRCodeScannerViewModel] unfollowUserWithFirebase: エラー - \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    } else {
                        print("✅ [QRCodeScannerViewModel] unfollowUserWithFirebase: 成功")
                        self?.isFollowingUser = false
                        self?.successMessage = "\(targetUser.name)さんのフォローを解除しました"

                        // フォロー解除後、現在のユーザー情報を更新
                        if let currentUserId = self?.authenticationManager.currentUserId {
                            self?.authenticationManager.loadCurrentUser(
                                uid: currentUserId
                            )
                        }
                    }
                    print("🔥 [QRCodeScannerViewModel] unfollowUserWithFirebase: 完了")
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func unfollowUserLocally(user: User) {
        print("📱 [QRCodeScannerViewModel] unfollowUserLocally: 開始 - user: \(user.name)")
        localFollowService.unfollowUser(user.id)
        isFollowingUser = false
        successMessage = "\(user.name)さんのフォローを解除しました"
        print("✅ [QRCodeScannerViewModel] unfollowUserLocally: 成功")
        print("📱 [QRCodeScannerViewModel] unfollowUserLocally: 完了")
    }

    // QRコードスキャン結果を処理
    func handleQRCodeScan(_ code: String) {
        print("📷 [QRCodeScannerViewModel] handleQRCodeScan: 開始 - code: \(code)")
        // エラーをクリアしてからユーザー検索を開始
        errorMessage = nil
        searchUserByInviteCode(code)
        print("📷 [QRCodeScannerViewModel] handleQRCodeScan: 完了")
    }

    // 入力をクリア
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
}

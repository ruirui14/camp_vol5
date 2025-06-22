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

    private let firestoreService = FirestoreService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()

    // 招待コードまたはQRコードからユーザー情報を取得
    func searchUserByInviteCode(_ code: String) {
        guard !code.isEmpty else {
            errorMessage = "招待コードを入力してください"
            return
        }

        inviteCode = code
        isLoading = true
        scannedUser = nil

        firestoreService.findUserByInviteCode(code)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    if let user = user {
                        self?.scannedUser = user
                        self?.checkIfAlreadyFollowing(user)
                    } else {
                        self?.errorMessage = "ユーザーが見つかりません"
                    }
                }
            )
            .store(in: &cancellables)
    }

    // 既にフォロー済みかチェック
    private func checkIfAlreadyFollowing(_ user: User) {
        guard let currentUserId = authService.currentUserId else { return }

        firestoreService.getUser(uid: currentUserId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] currentUser in
                    if let currentUser = currentUser {
                        self?.isFollowingUser = currentUser.followingUserIds
                            .contains(user.id)
                    }
                }
            )
            .store(in: &cancellables)
    }

    // ユーザーをフォロー
    func followUser() {
        guard let user = scannedUser,
            let currentUserId = authService.currentUserId
        else {
            errorMessage = "ユーザー情報が取得できません"
            return
        }

        // 自分自身はフォローできない
        if user.id == currentUserId {
            errorMessage = "自分自身をフォローすることはできません"
            return
        }

        // 既にフォロー済み
        if isFollowingUser {
            errorMessage = "既にフォロー済みです"
            return
        }

        isLoading = true

        firestoreService.followUser(
            followerId: currentUserId,
            followeeId: user.id
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.isFollowingUser = true
                    self?.successMessage = "\(user.name)さんをフォローしました"
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
    }

    // フォロー解除
    func unfollowUser() {
        guard let user = scannedUser,
            let currentUserId = authService.currentUserId
        else { return }

        isLoading = true

        firestoreService.unfollowUser(
            followerId: currentUserId,
            followeeId: user.id
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.isFollowingUser = false
                    self?.successMessage = "\(user.name)さんのフォローを解除しました"
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
    }

    // QRコードスキャン結果を処理
    func handleQRCodeScan(_ code: String) {
        searchUserByInviteCode(code)
    }

    // 入力をクリア
    func clearInput() {
        inviteCode = ""
        scannedUser = nil
        isFollowingUser = false
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

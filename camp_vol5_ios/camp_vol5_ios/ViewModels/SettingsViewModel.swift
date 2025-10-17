// ViewModels/SettingsViewModel.swift
// 設定画面のビューモデル - ユーザー情報の取得、招待コード管理、QR登録設定を担当
// BaseViewModelを継承し、プロトコルベースの依存性注入を使用

import Combine
import Foundation

@MainActor
class SettingsViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var currentHeartbeat: Heartbeat?
    @Published var inviteCode: String = ""
    @Published var allowQRRegistration: Bool = true

    // MARK: - Private Properties
    private var authenticationManager: AuthenticationManager
    private let userService: UserServiceProtocol
    private let heartbeatService: HeartbeatServiceProtocol

    // MARK: - Initialization

    init(
        authenticationManager: AuthenticationManager = AuthenticationManager(),
        userService: UserServiceProtocol = UserService.shared,
        heartbeatService: HeartbeatServiceProtocol = HeartbeatService.shared
    ) {
        self.authenticationManager = authenticationManager
        self.userService = userService
        self.heartbeatService = heartbeatService
        super.init()
        setupBindings()
    }

    private func setupBindings() {
        // 認証状態の監視
        authenticationManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                if let user = user {
                    self?.inviteCode = user.inviteCode
                    self?.allowQRRegistration = user.allowQRRegistration
                }
            }
            .store(in: &cancellables)

        // 認証状態とローディング状態の監視
        Publishers.CombineLatest(
            authenticationManager.$isAuthenticated,
            authenticationManager.$isLoading
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isAuthenticated, isLoading in
            // 認証が完了し、ローディングが終了したらユーザー情報を読み込む
            if isAuthenticated, !isLoading {
                self?.loadCurrentUserIfNeeded()
            }
        }
        .store(in: &cancellables)
    }

    private func loadCurrentUserIfNeeded() {
        // 既にユーザー情報がある場合は読み込みをスキップ
        // AuthenticationManagerから基本情報は取得済みだが、詳細情報が必要な場合は再取得する
        // guard currentUser == nil else { return }

        guard let userId = authenticationManager.currentUserId else {
            // 認証が必要な場合はエラーメッセージを表示しない
            return
        }

        userService.getUser(uid: userId)
            .handleErrors(on: self)
            .sink { [weak self] user in
                guard let self = self else { return }
                self.currentUser = user
                if let user = user {
                    self.inviteCode = user.inviteCode
                    self.allowQRRegistration = user.allowQRRegistration
                    self.loadCurrentHeartbeat()
                } else if self.errorMessage != nil {
                    // エラーの場合も空のユーザーオブジェクトを設定してUIの読み込み状態を終了
                    self.currentUser = User(
                        id: userId,
                        name: "Unknown",
                        inviteCode: "",
                        allowQRRegistration: false
                    )
                }
            }
            .store(in: &cancellables)
    }

    func loadCurrentUser() {
        guard let userId = authenticationManager.currentUserId else {
            errorMessage = "認証が必要です"
            return
        }

        userService.getUser(uid: userId)
            .handleErrors(on: self)
            .sink { [weak self] user in
                guard let self = self else { return }
                self.currentUser = user
                if let user = user {
                    self.inviteCode = user.inviteCode
                    self.allowQRRegistration = user.allowQRRegistration
                    self.loadCurrentHeartbeat()
                }
            }
            .store(in: &cancellables)
    }

    // 自分の心拍データを取得
    private func loadCurrentHeartbeat() {
        guard let userId = authenticationManager.currentUserId else { return }

        heartbeatService.getHeartbeatOnce(userId: userId)
            .handleErrors(on: self)
            .sink { [weak self] heartbeat in
                self?.currentHeartbeat = heartbeat
            }
            .store(in: &cancellables)
    }

    // 新しい招待コードを生成
    func generateNewInviteCode() {
        guard authenticationManager.currentUserId != nil else {
            errorMessage = "認証が必要です"
            return
        }

        guard let currentUser = authenticationManager.currentUser else {
            errorMessage = "Current user not found"
            return
        }

        isLoading = true

        userService.generateNewInviteCode(for: currentUser)
            .handleErrors(on: self)
            .sink { [weak self] newInviteCode in
                guard let self = self else { return }
                self.isLoading = false
                self.inviteCode = newInviteCode
                self.successMessage = "新しい招待コードを生成しました"
                // AuthServiceの現在のユーザー情報を更新
                self.authenticationManager.refreshCurrentUser()
            }
            .store(in: &cancellables)
    }

    // QR登録許可設定を切り替え
    func toggleQRRegistration() {
        guard authenticationManager.currentUserId != nil else {
            errorMessage = "認証が必要です"
            return
        }

        guard let currentUser = authenticationManager.currentUser else {
            errorMessage = "Current user not found"
            return
        }

        // 現在のallowQRRegistrationの値を使用
        let newValue = allowQRRegistration
        isLoading = true

        userService.updateQRRegistrationSetting(for: currentUser, allow: newValue)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    if case let .failure(error) = completion {
                        // エラーの場合、トグルを元に戻す
                        self.allowQRRegistration = !newValue
                        self.handleError(error)
                    } else {
                        // 成功メッセージを表示
                        self.successMessage =
                            newValue ? "QR登録を許可しました" : "QR登録を無効にしました"
                        // AuthServiceの現在のユーザー情報を更新
                        self.authenticationManager.refreshCurrentUser()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    // 心拍データを手動更新
    func refreshHeartbeat() {
        guard authenticationManager.currentUserId != nil else {
            errorMessage = "認証が必要です"
            return
        }

        loadCurrentHeartbeat()
    }

    // MARK: - Authentication

    func signOut() {
        if authenticationManager.isAuthenticated {
            // 認証済みユーザーの場合は通常のサインアウト
            authenticationManager.signOut()
        } else {
            // 未認証ユーザーの場合はアプリ状態をリセット
            authenticationManager.resetAppState()
        }
    }
}

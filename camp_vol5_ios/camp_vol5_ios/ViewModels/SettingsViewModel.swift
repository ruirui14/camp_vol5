// ViewModels/SettingsViewModel.swift
import Combine
import Foundation

class SettingsViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var currentHeartbeat: Heartbeat?
    @Published var inviteCode: String = ""
    @Published var allowQRRegistration: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

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
            if isAuthenticated && !isLoading {
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

        UserService.shared.getUser(uid: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: {
                    [weak self] (completion: Subscribers.Completion<Error>) in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        // エラーの場合も空のユーザーオブジェクトを設定してUIの読み込み状態を終了
                        self?.currentUser = User(
                            id: userId, name: "Unknown", inviteCode: "", allowQRRegistration: false)
                    }
                },
                receiveValue: { [weak self] (user: User?) in
                    self?.currentUser = user
                    if let user = user {
                        self?.inviteCode = user.inviteCode
                        self?.allowQRRegistration = user.allowQRRegistration
                        self?.loadCurrentHeartbeat()
                    }
                }
            )
            .store(in: &cancellables)
    }

    func loadCurrentUser() {
        guard let userId = authenticationManager.currentUserId else {
            errorMessage = "認証が必要です"
            return
        }

        UserService.shared.getUser(uid: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: {
                    [weak self] (completion: Subscribers.Completion<Error>) in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] (user: User?) in
                    self?.currentUser = user
                    if let user = user {
                        self?.inviteCode = user.inviteCode
                        self?.allowQRRegistration = user.allowQRRegistration
                        self?.loadCurrentHeartbeat()
                    }
                }
            )
            .store(in: &cancellables)
    }

    // 自分の心拍データを取得
    private func loadCurrentHeartbeat() {
        guard let userId = authenticationManager.currentUserId else { return }

        HeartbeatService.shared.getHeartbeatOnce(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] heartbeat in
                    self?.currentHeartbeat = heartbeat
                }
            )
            .store(in: &cancellables)
    }

    // 新しい招待コードを生成
    func generateNewInviteCode() {
        guard let userId = authenticationManager.currentUserId else {
            errorMessage = "認証が必要です"
            return
        }

        isLoading = true

        guard let currentUser = authenticationManager.currentUser else {
            errorMessage = "Current user not found"
            isLoading = false
            return
        }

        UserService.shared.generateNewInviteCode(for: currentUser)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] newInviteCode in
                    self?.inviteCode = newInviteCode
                    self?.successMessage = "新しい招待コードを生成しました"
                    // AuthServiceの現在のユーザー情報を更新
                    self?.authenticationManager.refreshCurrentUser()
                }
            )
            .store(in: &cancellables)
    }

    // QR登録許可設定を切り替え
    func toggleQRRegistration() {
        guard let userId = authenticationManager.currentUserId else {
            errorMessage = "認証が必要です"
            return
        }

        // 現在のallowQRRegistrationの値を使用
        let newValue = allowQRRegistration
        isLoading = true

        guard let currentUser = authenticationManager.currentUser else {
            errorMessage = "Current user not found"
            return
        }

        UserService.shared.updateQRRegistrationSetting(for: currentUser, allow: newValue)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        // エラーの場合、トグルを元に戻す
                        self?.allowQRRegistration = !newValue
                        self?.errorMessage = error.localizedDescription
                    } else {
                        // 成功メッセージを表示
                        self?.successMessage =
                            newValue ? "QR登録を許可しました" : "QR登録を無効にしました"
                        // AuthServiceの現在のユーザー情報を更新
                        self?.authenticationManager.refreshCurrentUser()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    // 心拍データを手動更新
    func refreshHeartbeat() {
        guard let userId = authenticationManager.currentUserId else {
            errorMessage = "認証が必要です"
            return
        }

        loadCurrentHeartbeat()
    }

    // MARK: - Authentication

    func signOut() {
        authenticationManager.signOut()
    }

    // エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }

    // 成功メッセージをクリア
    func clearSuccessMessage() {
        successMessage = nil
    }
}

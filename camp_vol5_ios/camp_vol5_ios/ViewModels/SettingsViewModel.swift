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

    private let authService = AuthService.shared
    private let firestoreService = FirestoreService.shared
    private let realtimeService = RealtimeService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // 認証状態の監視
        authService.$currentUser
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
            authService.$isAuthenticated,
            authService.$isLoading
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
        guard currentUser == nil else { return }

        guard let userId = authService.currentUserId else {
            // 認証が必要な場合はエラーメッセージを表示しない
            return
        }

        firestoreService.getUser(uid: userId)
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

    func loadCurrentUser() {
        guard let userId = authService.currentUserId else {
            errorMessage = "認証が必要です"
            return
        }

        firestoreService.getUser(uid: userId)
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
        guard let userId = authService.currentUserId else { return }

        realtimeService.getHeartbeatOnce(userId: userId)
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
        guard let userId = authService.currentUserId else {
            errorMessage = "認証が必要です"
            return
        }

        isLoading = true

        firestoreService.generateNewInviteCode(for: userId)
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
                    self?.authService.refreshCurrentUser()
                }
            )
            .store(in: &cancellables)
    }

    // QR登録許可設定を切り替え
    func toggleQRRegistration() {
        guard let userId = authService.currentUserId else {
            errorMessage = "認証が必要です"
            return
        }

        // 現在のallowQRRegistrationの値を使用
        let newValue = allowQRRegistration
        isLoading = true

        firestoreService.updateQRRegistrationSetting(
            userId: userId,
            allowQRRegistration: newValue
        )
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
                    self?.authService.refreshCurrentUser()
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
    }

    // 心拍データを手動更新
    func refreshHeartbeat() {
        guard let userId = authService.currentUserId else {
            errorMessage = "認証が必要です"
            return
        }

        loadCurrentHeartbeat()
    }

    // MARK: - Authentication

    func signOut() {
        authService.signOut()
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

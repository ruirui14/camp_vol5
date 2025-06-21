import Combine
// ViewModels/MainViewModel.swift
import Foundation

class MainViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUserName: String = ""
    @Published var connectionStatus: String = "未接続"
    @Published var errorMessage: String?

    private let authService = AuthService.shared
    private let firestoreService = FirestoreService.shared
    private let realtimeService = RealtimeService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // 認証状態の監視
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)

        // 認証エラーの監視
        authService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)

        // Realtime Database接続状態の監視
        realtimeService.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .connected:
                    self?.connectionStatus = "接続中"
                case .disconnected:
                    self?.connectionStatus = "未接続"
                case .error(let message):
                    self?.connectionStatus = "エラー: \(message)"
                }
            }
            .store(in: &cancellables)

        // ユーザー情報の取得
        authService.$currentAppUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if let user = user {
                    self?.currentUserName = user.name  // Userのnameプロパティに直接アクセス
                } else {
                    self?.currentUserName = ""
                }
            }
            .store(in: &cancellables)
    }

    // サインアウト
    func signOut() {
        authService.signOut()
    }

    // エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
}

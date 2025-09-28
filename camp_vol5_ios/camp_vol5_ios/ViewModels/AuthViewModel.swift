// ViewModels/AuthViewModel.swift
// AuthenticationManagerを使用した認証状態管理とAuthView用のUI状態管理
// AuthViewの全ビジネスロジックをViewModelに集約

import Combine
import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedAuthMethod: AuthMethod = .none
    @Published var showEmailAuth = false
    @Published var animateContent = false
    @Published var showError = false

    // MARK: - Types
    enum AuthMethod {
        case none, google, email, anonymous
    }

    // MARK: - Dependencies
    private var authenticationManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        setupBindings()
        startAnimation()
    }

    func updateAuthenticationManager(_ authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        cancellables.removeAll()
        setupBindings()
    }

    private func setupBindings() {
        // AuthenticationManagerの状態をViewModelに反映
        authenticationManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)

        authenticationManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func signInWithGoogle() {
        selectedAuthMethod = .google
        authenticationManager.selectedAuthMethod = "google"
        authenticationManager.signInWithGoogle()
    }

    func signInAnonymously() {
        selectedAuthMethod = .anonymous
        authenticationManager.selectedAuthMethod = "anonymous"
        authenticationManager.signInAnonymously()
    }

    func showEmailAuthModal() {
        selectedAuthMethod = .email
        authenticationManager.selectedAuthMethod = "email"
        showEmailAuth = true
    }

    func dismissEmailAuth() {
        showEmailAuth = false
        selectedAuthMethod = .none
    }

    func clearError() {
        authenticationManager.clearError()
        selectedAuthMethod = .none
    }

    private func startAnimation() {
        animateContent = true
    }

    // MARK: - Computed Properties

    var isAuthenticated: Bool {
        return authenticationManager.isAuthenticated
    }

    var isGoogleLoading: Bool {
        return authenticationManager.isLoading && selectedAuthMethod == .google
    }
}

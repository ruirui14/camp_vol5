// ViewModels/AuthViewModel.swift
// AuthenticationManagerを使用した認証状態管理とAuthView用のUI状態管理
// AuthViewの全ビジネスロジックをViewModelに集約

import Combine
import Foundation

@MainActor
class AuthViewModel: BaseViewModel {
    // MARK: - Published Properties
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

    init(authenticationManager: AuthenticationManager = AuthenticationManager()) {
        self.authenticationManager = authenticationManager
        super.init()
        setupBindings()
        startAnimation()
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

        // メール確認待ち状態の場合、EmailAuthシートを開いたままにする
        authenticationManager.$needsEmailVerification
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needsVerification in
                if needsVerification && self?.selectedAuthMethod == .email {
                    // メール確認待ち状態になったら、シートを開く
                    self?.showEmailAuth = true
                }
            }
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

    override func clearError() {
        authenticationManager.clearError()
        selectedAuthMethod = .none
    }

    private func startAnimation() {
        animateContent = true
    }

    // MARK: - Computed Properties

    var isAuthenticated: Bool {
        authenticationManager.isAuthenticated
    }

    var isGoogleLoading: Bool {
        authenticationManager.isLoading && selectedAuthMethod == .google
    }
}

// ViewModels/EmailAuthViewModel.swift
// メール・パスワード認証用ViewModel
// サインインとサインアップ機能のビジネスロジックを管理

import Combine
import Foundation
import SwiftUI

@MainActor
class EmailAuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var isSignUp: Bool = false
    @Published var showPassword: Bool = false
    @Published var animateForm: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

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

    func toggleAuthMode() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isSignUp.toggle()
        }
        // フォーム変更時にエラーをクリア
        clearError()
    }

    func togglePasswordVisibility() {
        showPassword.toggle()
    }

    func signInWithEmail() {
        guard validateForm() else { return }

        if isSignUp {
            authenticationManager.signUpWithEmailOnly(email: email, password: password)
        } else {
            authenticationManager.signInWithEmail(email: email, password: password)
        }
    }

    func clearError() {
        authenticationManager.clearError()
    }

    private func startAnimation() {
        animateForm = true
    }

    private func validateForm() -> Bool {
        // 入力値の基本的な検証
        if email.isEmpty || password.isEmpty {
            // エラー処理はAuthenticationManagerで行う
            return false
        }

        // 基本的なメールバリデーション
        if !isValidEmail(email) {
            return false
        }

        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // MARK: - Computed Properties

    var isAuthenticated: Bool {
        return authenticationManager.isAuthenticated
    }

    var authModeTitle: String {
        return isSignUp ? "アカウント作成" : "サインイン"
    }

    var authModeSubtitle: String {
        return isSignUp ? "新しいアカウントを作成します" : "既存のアカウントでログインします"
    }

    var primaryButtonTitle: String {
        if isLoading {
            return isSignUp ? "アカウント作成中..." : "サインイン中..."
        }
        return isSignUp ? "アカウント作成" : "サインイン"
    }

    var toggleModeText: String {
        return isSignUp ? "既存のアカウントでサインイン" : "新しいアカウントを作成"
    }

    var isFormValid: Bool {
        if email.isEmpty || password.isEmpty {
            return false
        }
        if !isValidEmail(email) {
            return false
        }
        return true
    }
}
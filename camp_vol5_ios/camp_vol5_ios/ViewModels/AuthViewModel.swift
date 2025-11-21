// ViewModels/AuthViewModel.swift
// AuthenticationManagerを使用した認証状態管理とAuthView用のUI状態管理
// AuthViewの全ビジネスロジックをViewModelに集約

import Combine
import Foundation
import SwiftUI

@MainActor
class AuthViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var selectedAuthMethod: AuthMethod = .none
    @Published var showEmailAuth = false
    @Published var animateContent = false
    @Published var showError = false

    // メール認証関連
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isSignUp: Bool = false
    @Published var showPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    @Published var needsEmailVerification: Bool = false
    @Published var isEmailVerified: Bool = false
    @Published var showPasswordReset: Bool = false
    @Published var resetEmail: String = ""
    @Published var passwordResetSent: Bool = false

    // MARK: - Types
    enum AuthMethod {
        case none, google, apple, email, anonymous
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
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
                // エラーが発生したら認証メソッドをリセット
                if errorMessage != nil {
                    self?.selectedAuthMethod = .none
                }
            }
            .store(in: &cancellables)

        // メール確認待ち状態の場合、EmailAuthシートを開いたままにする
        authenticationManager.$needsEmailVerification
            .receive(on: DispatchQueue.main)
            .assign(to: \.needsEmailVerification, on: self)
            .store(in: &cancellables)

        authenticationManager.$isEmailVerified
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEmailVerified, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func signInWithGoogle() {
        selectedAuthMethod = .google
        authenticationManager.selectedAuthMethod = "google"
        authenticationManager.signInWithGoogle()
    }

    func signInWithApple() {
        selectedAuthMethod = .apple
        authenticationManager.selectedAuthMethod = "apple"
        authenticationManager.signInWithApple()
    }

    func signInAnonymously() {
        selectedAuthMethod = .anonymous
        authenticationManager.selectedAuthMethod = "anonymous"
        authenticationManager.signInAnonymously()
    }

    // MARK: - Email Authentication

    func toggleAuthMode() {
        isSignUp.toggle()
        clearError()
    }

    func signInWithEmail() {
        // 認証メソッドを設定
        selectedAuthMethod = .email
        authenticationManager.selectedAuthMethod = "email"

        // バリデーション
        if email.isEmpty {
            authenticationManager.errorMessage = "メールアドレスを入力してください"
            selectedAuthMethod = .none
            return
        }

        if password.isEmpty {
            authenticationManager.errorMessage = "パスワードを入力してください"
            selectedAuthMethod = .none
            return
        }

        // 新規登録時はパスワード確認が必要
        if isSignUp {
            if !isValidEmail(email) {
                authenticationManager.errorMessage = "有効なメールアドレスを入力してください"
                selectedAuthMethod = .none
                return
            }

            if password.count < 8 {
                authenticationManager.errorMessage = "パスワードは8文字以上で入力してください"
                selectedAuthMethod = .none
                return
            }

            if confirmPassword.isEmpty {
                authenticationManager.errorMessage = "確認用パスワードを入力してください"
                selectedAuthMethod = .none
                return
            }

            if password != confirmPassword {
                authenticationManager.errorMessage = "パスワードが一致しません"
                selectedAuthMethod = .none
                return
            }
        }

        if isSignUp {
            authenticationManager.signUpWithEmailOnly(email: email, password: password)
        } else {
            authenticationManager.signInWithEmail(email: email, password: password)
        }
    }

    func sendVerificationEmail() {
        authenticationManager.sendVerificationEmail()
    }

    func checkEmailVerification() {
        authenticationManager.reloadUserAndCheckVerification()
    }

    func toggleEmailVerification() {
        authenticationManager.toggleEmailVerification()
    }

    // MARK: - Password Reset

    func showPasswordResetSheet() {
        resetEmail = email
        passwordResetSent = false
        showPasswordReset = true
    }

    func sendPasswordResetEmail() {
        authenticationManager.sendPasswordResetEmail(email: resetEmail)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if self?.authenticationManager.errorMessage == nil {
                self?.passwordResetSent = true
            }
        }
    }

    func dismissPasswordReset() {
        showPasswordReset = false
        passwordResetSent = false
        resetEmail = ""
    }

    // MARK: - Validation

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    override func clearError() {
        authenticationManager.clearError()
    }

    private func startAnimation() {
        animateContent = true
    }

    // MARK: - Computed Properties

    var isAuthenticated: Bool {
        authenticationManager.isAuthenticated
    }

    var isAnonymousLoading: Bool {
        authenticationManager.isLoading && selectedAuthMethod == .anonymous
    }

    var isGoogleLoading: Bool {
        authenticationManager.isLoading && selectedAuthMethod == .google
    }

    var isAppleLoading: Bool {
        authenticationManager.isLoading && selectedAuthMethod == .apple
    }

    var isEmailLoading: Bool {
        authenticationManager.isLoading && selectedAuthMethod == .email
    }

    var isFormValid: Bool {
        // 入力が空でないかどうかだけをチェック
        // 詳細なバリデーションはsignInWithEmailで行う
        if isSignUp {
            // 新規登録時はパスワード確認も必要
            return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
                && password == confirmPassword
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    var hasUnverifiedEmailUser: Bool {
        authenticationManager.hasUnverifiedEmailUser
    }
}

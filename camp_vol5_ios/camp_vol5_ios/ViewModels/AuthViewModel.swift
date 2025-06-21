// ViewModels/AuthViewModel.swift
import Combine
import Foundation

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSignUpMode: Bool = false

    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 認証サービスの状態を監視
        authService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)

        authService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }

    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください"
            return
        }

        authService.signIn(email: email, password: password)
    }

    func signUp() {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            errorMessage = "全ての項目を入力してください"
            return
        }

        authService.signUp(email: email, password: password, name: name)
    }

    func toggleMode() {
        isSignUpMode.toggle()
        clearFields()
    }

    func clearFields() {
        email = ""
        password = ""
        name = ""
        errorMessage = nil
    }
}

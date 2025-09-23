// ViewModels/AuthViewModel.swift
// AuthenticationManagerを使用した認証状態管理
// 注意: AuthenticationManagerが直接ObservableObjectなので、このViewModelは簡素化されている

import Combine
import Foundation

class AuthViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

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
        authenticationManager.signInWithGoogle()
    }

    func clearError() {
        authenticationManager.clearError()
    }

    // MARK: - Computed Properties

    var isAuthenticated: Bool {
        return authenticationManager.isAuthenticated
    }
}

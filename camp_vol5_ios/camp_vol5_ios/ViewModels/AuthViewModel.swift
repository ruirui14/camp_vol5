// ViewModels/AuthViewModel.swift
import Combine
import Foundation

class AuthViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // AuthServiceの状態をViewModelに反映
        authService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)

        authService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func signInWithGoogle() {
        authService.signInWithGoogle()
    }

    func clearError() {
        authService.clearError()
    }

    // MARK: - Computed Properties

    var isAuthenticated: Bool {
        return authService.isAuthenticated
    }

    var isAnonymous: Bool {
        return authService.isAnonymous
    }

    var isGoogleAuthenticated: Bool {
        return authService.isGoogleAuthenticated
    }
}

import Combine
import Foundation

class QRCodeShareViewModel: ObservableObject {
    @Published var inviteCode: String?
    @Published var isLoading = false
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
        authenticationManager.$currentUser
            .map { $0?.inviteCode }
            .receive(on: DispatchQueue.main)
            .assign(to: \.inviteCode, on: self)
            .store(in: &cancellables)
    }

    func generateNewInviteCode() {
        guard let userId = authenticationManager.currentUserId else {
            errorMessage = "User not logged in"
            return
        }

        isLoading = true
        errorMessage = nil

        guard let currentUser = authenticationManager.currentUser else {
            errorMessage = "User not logged in"
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
                receiveValue: { [weak self] _ in
                    self?.authenticationManager.refreshCurrentUser()
                }
            )
            .store(in: &cancellables)
    }
}

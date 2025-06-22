import Combine
import Foundation

class QRCodeShareViewModel: ObservableObject {
    @Published var inviteCode: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared
    private let firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        authService.$currentUser
            .map { $0?.inviteCode }
            .receive(on: DispatchQueue.main)
            .assign(to: \.inviteCode, on: self)
            .store(in: &cancellables)
    }

    func generateNewInviteCode() {
        guard let userId = authService.currentUserId else {
            errorMessage = "User not logged in"
            return
        }

        isLoading = true
        errorMessage = nil

        firestoreService.generateNewInviteCode(for: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.authService.refreshCurrentUser()
                }
            )
            .store(in: &cancellables)
    }
}

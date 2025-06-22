// Services/AuthService.swift
import Combine
import Firebase
import FirebaseAuth

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var user: FirebaseAuth.User?
    @Published var currentAppUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil

                if let user = user {
                    self?.loadCurrentAppUser(uid: user.uid)
                } else {
                    self?.currentAppUser = nil
                }
            }
        }
    }

    private func loadCurrentAppUser(uid: String) {
        firestoreService.getUser(uid: uid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentAppUser = user
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Authentication Methods

    func signUp(email: String, password: String, name: String) {
        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) {
            [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    // Firestoreにユーザー情報を保存
                    self?.saveUserToFirestore(uid: user.uid, name: name)
                }
            }
        }
    }

    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) {
            [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            currentAppUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - User Management

    private func saveUserToFirestore(uid: String, name: String) {
        firestoreService.createUser(uid: uid, name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentAppUser = user
                }
            )
            .store(in: &cancellables)
    }

    // 現在のユーザーID取得
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }

    // 現在のユーザー情報更新
    func updateCurrentUser(_ user: User) {
        firestoreService.updateUser(user)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] updatedUser in
                    self?.currentAppUser = updatedUser
                }
            )
            .store(in: &cancellables)
    }
}

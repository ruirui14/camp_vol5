// Services/AuthenticationManager.swift
// Firebase認証を管理するEnvironmentObject対応のマネージャー
// シングルトンパターンを廃止し、SwiftUIのベストプラクティスに従った実装

import Combine
import Firebase
import FirebaseAuth
import Foundation
import GoogleSignIn

// MARK: - Authentication Protocol

/// 認証機能のプロトコル（テスト用の抽象化）
protocol AuthenticationProtocol: ObservableObject {
    var user: FirebaseAuth.User? { get }
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isGoogleAuthenticated: Bool { get }
    var currentUserId: String? { get }

    func signInWithGoogle()
    func signInWithEmail(email: String, password: String)
    func signUpWithEmail(email: String, password: String, name: String)
    func signOut()
    func refreshCurrentUser()
    func updateCurrentUser(_ user: User)
    func clearError()
}

// MARK: - Authentication Manager

/// Firebase認証とユーザー状態を管理するメインクラス
/// EnvironmentObjectとして使用される
final class AuthenticationManager: ObservableObject, AuthenticationProtocol {
    // MARK: - Published Properties

    /// Firebase認証ユーザー
    @Published var user: FirebaseAuth.User?

    /// アプリケーション内のユーザー情報
    @Published var currentUser: User?

    /// 認証状態
    @Published var isAuthenticated: Bool = false

    /// 認証処理中かどうか
    @Published var isLoading: Bool = false

    /// エラーメッセージ
    @Published var errorMessage: String?

    // MARK: - Private Properties

    // Firebase Service削除に伴い、直接Modelを使用
    private var cancellables = Set<AnyCancellable>()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    // MARK: - Initialization

    /// 初期化
    init() {
        setupAuthStateListener()
        // 初期化時に現在の認証状態をチェック
        DispatchQueue.main.async {
            self.updateAuthenticationState(with: Auth.auth().currentUser)
        }
    }

    deinit {
        // リスナーの適切な削除
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Private Methods

    /// Firebase認証状態の監視を設定
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            DispatchQueue.main.async {
                self?.updateAuthenticationState(with: firebaseUser)
            }
        }
    }

    /// 認証状態の更新
    /// - Parameter firebaseUser: Firebaseユーザー
    private func updateAuthenticationState(with firebaseUser: FirebaseAuth.User?) {
        user = firebaseUser
        isAuthenticated = firebaseUser != nil

        if let user = firebaseUser {
            handleAuthenticatedUser(user)
        } else {
            handleUnauthenticatedUser()
        }

        // 認証状態確定後のローディング終了
        isLoading = false
    }

    /// 認証済みユーザーの処理
    /// - Parameter firebaseUser: Firebaseユーザー
    private func handleAuthenticatedUser(_ firebaseUser: FirebaseAuth.User) {
        // Google認証またはメール認証ユーザーの場合、Firestoreからユーザー情報を取得
        loadCurrentUser(uid: firebaseUser.uid)
    }

    /// 未認証ユーザーの処理
    private func handleUnauthenticatedUser() {
        currentUser = nil
        isLoading = false
    }

    /// Firestoreからユーザー情報を取得
    /// - Parameter uid: ユーザーID
    func loadCurrentUser(uid: String) {
        UserService.shared.getUser(uid: uid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    if case let .failure(error) = completion {
                        // エラーメッセージは設定しない（新規ユーザーの場合は正常）
                    }
                },
                receiveValue: { [weak self] (user: User?) in
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Googleサインイン
    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first,
            let rootViewController = window.rootViewController
        else {
            errorMessage = "アプリの初期化エラーが発生しました"
            return
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Google認証の設定エラーです"
            return
        }

        // Google Sign In設定
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        isLoading = true
        errorMessage = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) {
            [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "Google認証に失敗しました: \(error.localizedDescription)"
                    return
                }

                guard let user = result?.user,
                    let idToken = user.idToken?.tokenString
                else {
                    self?.errorMessage = "Google認証の情報取得に失敗しました"
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )

                // Google認証でサインイン
                self?.signInWithCredential(credential: credential, googleUser: user)
            }
        }
    }

    /// サインアウト
    func signOut() {
        do {
            // Firebase Sign Out
            try Auth.auth().signOut()

            // Google Sign Out
            GIDSignIn.sharedInstance.signOut()

            currentUser = nil
        } catch {
            errorMessage = "サインアウトに失敗しました: \(error.localizedDescription)"
        }
    }

    /// 現在のユーザー情報を再取得
    func refreshCurrentUser() {
        guard let uid = user?.uid else { return }
        loadCurrentUser(uid: uid)
    }

    /// ユーザー情報を更新
    /// - Parameter user: 更新するユーザー情報
    func updateCurrentUser(_ user: User) {
        guard isAuthenticated else { return }

        UserService.shared.updateUser(user)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] (updatedUser: User) in
                    self?.currentUser = updatedUser
                }
            )
            .store(in: &cancellables)
    }

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }

    /// アプリ状態をリセット（未認証ユーザーのサインアウト用）
    func resetAppState() {
        UserDefaults.standard.set(false, forKey: "hasStartedWithoutAuth")
        // 認証状態の変更を通知（ContentViewの更新をトリガー）
        objectWillChange.send()
    }

    /// メール・パスワードでサインイン
    /// - Parameters:
    ///   - email: メールアドレス
    ///   - password: パスワード
    func signInWithEmail(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    self?.errorMessage = "ユーザー情報の取得に失敗しました"
                    return
                }

                // 既存ユーザーの場合、Firestoreからユーザー情報を取得
                self?.loadCurrentUser(uid: firebaseUser.uid)
            }
        }
    }

    /// メール・パスワードでサインアップ
    /// - Parameters:
    ///   - email: メールアドレス
    ///   - password: パスワード
    ///   - name: 表示名
    func signUpWithEmail(email: String, password: String, name: String) {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            errorMessage = "すべての項目を入力してください"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "パスワードは6文字以上で入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "アカウント作成に失敗しました: \(error.localizedDescription)"
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    self?.errorMessage = "ユーザー情報の取得に失敗しました"
                    return
                }

                // 新規ユーザーの場合、Firestoreにユーザー情報を保存
                self?.saveUserToFirestore(uid: firebaseUser.uid, name: name)
            }
        }
    }

    // MARK: - Computed Properties

    /// 現在のユーザーID
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }

    /// Google認証ユーザーかどうか
    var isGoogleAuthenticated: Bool {
        guard let user = user else { return false }
        return user.providerData.contains { provider in
            provider.providerID == "google.com"
        }
    }


    // MARK: - Private Google Authentication Methods

    /// 通常のGoogle認証
    /// - Parameters:
    ///   - credential: Google認証クレデンシャル
    ///   - googleUser: Googleユーザー情報
    private func signInWithCredential(credential: AuthCredential, googleUser: GIDGoogleUser) {
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "認証に失敗しました: \(error.localizedDescription)"
                } else if let firebaseUser = authResult?.user {
                    if authResult?.additionalUserInfo?.isNewUser == true {
                        let displayName = googleUser.profile?.name ?? "Google User"
                        self?.saveUserToFirestore(uid: firebaseUser.uid, name: displayName)
                    } else {
                        self?.loadCurrentUser(uid: firebaseUser.uid)
                    }
                }
            }
        }
    }

    /// Firestoreにユーザー情報を保存
    /// - Parameters:
    ///   - uid: ユーザーID
    ///   - name: ユーザー名
    private func saveUserToFirestore(uid: String, name: String) {
        UserService.shared.createUser(uid: uid, name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    if case let .failure(error) = completion {
                        self?.errorMessage = "ユーザー情報の保存に失敗しました: \(error.localizedDescription)"
                    } else {
                        // 保存成功後、最新のユーザー情報を再取得
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self?.refreshCurrentUser()
                        }
                    }
                },
                receiveValue: { [weak self] (user: User) in
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Mock Authentication Manager (テスト用)

/// テスト用のモック認証マネージャー
final class MockAuthenticationManager: ObservableObject, AuthenticationProtocol {
    @Published var user: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var currentUserId: String? { user?.uid }
    var isGoogleAuthenticated: Bool { isAuthenticated }

    init(isAuthenticated: Bool = false, currentUser: User? = nil) {
        self.isAuthenticated = isAuthenticated
        self.currentUser = currentUser
    }

    func signInWithGoogle() {
        isAuthenticated = true
    }

    func signInWithEmail(email: String, password: String) {
        isAuthenticated = true
    }

    func signUpWithEmail(email: String, password: String, name: String) {
        isAuthenticated = true
    }

    func signOut() {
        isAuthenticated = false
        currentUser = nil
    }

    func refreshCurrentUser() {}
    func updateCurrentUser(_ user: User) { currentUser = user }
    func clearError() { errorMessage = nil }
}

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
    func signInAnonymously()
    func signOut()
    func refreshCurrentUser()
    func updateCurrentUser(_ user: User)
    func clearError()
    func deleteAccount()
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

    /// ユーザー名入力が必要かどうか
    @Published var needsUserNameInput: Bool = false

    /// 選択された認証方式
    @Published var selectedAuthMethod: String = "anonymous"

    /// メールアドレスが確認済みかどうか
    @Published var isEmailVerified: Bool = false

    /// メール確認待ち状態
    @Published var needsEmailVerification: Bool = false

    // MARK: - Private Properties

    // Firebase Service削除に伴い、直接Modelを使用
    var cancellables = Set<AnyCancellable>()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    // MARK: - Initialization

    /// 初期化
    init() {
        print("🔥 AuthenticationManager init started")
        print(
            "🔥 Initial state - isLoading: \(isLoading), needsUserNameInput: \(needsUserNameInput), isAuthenticated: \(isAuthenticated)"
        )
        setupAuthStateListener()
        // 初期化時に現在の認証状態をチェック（遅延実行でFirebase初期化完了を待つ）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🔥 Calling updateAuthenticationState after 0.5s delay")
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
        print("🔥 updateAuthenticationState called with user: \(firebaseUser?.uid ?? "nil")")
        user = firebaseUser
        isAuthenticated = firebaseUser != nil
        print("🔥 isAuthenticated set to: \(isAuthenticated)")

        if let user = firebaseUser {
            print("🔥 Handling authenticated user: \(user.uid), isAnonymous: \(user.isAnonymous)")
            handleAuthenticatedUser(user)
        } else {
            print("🔥 Handling unauthenticated user")
            handleUnauthenticatedUser()
        }

        // 認証状態確定後のローディング終了
        isLoading = false
        print(
            "🔥 Final state - isLoading: \(isLoading), needsUserNameInput: \(needsUserNameInput), isAuthenticated: \(isAuthenticated), currentUser: \(currentUser != nil)"
        )
    }

    /// 認証済みユーザーの処理
    /// - Parameter firebaseUser: Firebaseユーザー
    private func handleAuthenticatedUser(_ firebaseUser: FirebaseAuth.User) {
        print("🔥 handleAuthenticatedUser - isAnonymous: \(firebaseUser.isAnonymous)")

        // 匿名ユーザーの場合は基本的なユーザー情報を作成
        if firebaseUser.isAnonymous {
            handleAnonymousUser(firebaseUser)
        } else {
            // メール認証ユーザーの場合、メール確認状態をチェック
            let isEmailProvider = firebaseUser.providerData.contains { $0.providerID == "password" }

            if isEmailProvider && !firebaseUser.isEmailVerified {
                // メール未確認の場合、メール確認画面を表示
                print("⚠️ Email not verified for user: \(firebaseUser.uid)")
                isEmailVerified = false
                needsEmailVerification = true
                needsUserNameInput = false
                return
            }

            // Google認証またはメール確認済みユーザーの場合、既存ユーザーをチェック
            print("🔥 Checking existing user for authenticated user: \(firebaseUser.uid)")
            isEmailVerified = firebaseUser.isEmailVerified
            needsEmailVerification = false
            checkExistingUserOrRequireNameInput(uid: firebaseUser.uid, firebaseUser: firebaseUser)
        }
    }

    /// 匿名ユーザーの処理
    /// - Parameter firebaseUser: 匿名Firebaseユーザー
    private func handleAnonymousUser(_ firebaseUser: FirebaseAuth.User) {
        // 匿名ユーザーの場合、ユーザー名入力画面に遷移
        print("🔥 Setting needsUserNameInput = true for anonymous user")
        needsUserNameInput = true
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
                receiveCompletion: { _ in
                    // エラーメッセージは設定しない（新規ユーザーの場合は正常）
                },
                receiveValue: { [weak self] (user: User?) in
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)
    }

    /// 既存ユーザーをチェックし、存在しない場合はユーザー名入力を要求
    /// - Parameters:
    ///   - uid: ユーザーID
    ///   - firebaseUser: Firebaseユーザー
    private func checkExistingUserOrRequireNameInput(uid: String, firebaseUser: FirebaseAuth.User) {
        // メール認証ユーザーの場合、メール確認状態を再チェック
        let isEmailProvider = firebaseUser.providerData.contains { $0.providerID == "password" }
        if isEmailProvider && !firebaseUser.isEmailVerified {
            print("⚠️ Email not verified, showing verification screen")
            isEmailVerified = false
            needsEmailVerification = true
            needsUserNameInput = false
            return
        }

        UserService.shared.getUser(uid: uid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    if case .failure(_) = completion {
                        // ユーザーが見つからない場合、ユーザー名入力画面に遷移
                        print("🔥 User not found, requiring name input")
                        self?.needsUserNameInput = true
                        // 認証方式を設定（既に AuthView で設定済みだが、念のため）
                        if self?.selectedAuthMethod.isEmpty == true {
                            let isEmail = firebaseUser.providerData.contains {
                                $0.providerID == "password"
                            }
                            self?.selectedAuthMethod = isEmail ? "email" : "google"
                        }
                    }
                },
                receiveValue: { [weak self] (user: User?) in
                    if let user = user {
                        // 既存ユーザーが見つかった場合、直接ログイン
                        print("🔥 Existing user found: \(user.name), skipping name input")
                        self?.currentUser = user
                        self?.needsUserNameInput = false
                    } else {
                        // ユーザーが見つからない場合、ユーザー名入力画面に遷移
                        print("🔥 User not found, requiring name input")
                        self?.needsUserNameInput = true
                        // 認証方式を設定（既に AuthView で設定済みだが、念のため）
                        if self?.selectedAuthMethod.isEmpty == true {
                            let isEmail = firebaseUser.providerData.contains {
                                $0.providerID == "password"
                            }
                            self?.selectedAuthMethod = isEmail ? "email" : "google"
                        }
                    }
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
                receiveValue: { [weak self] _ in
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)
    }

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }

    /// アカウントを削除
    func deleteAccount() {
        guard let firebaseUser = user else {
            errorMessage = "認証されたユーザーがいません"
            return
        }

        isLoading = true
        errorMessage = nil

        // Firestoreからユーザードキュメントを削除
        if let currentUser = currentUser {
            UserService.shared.deleteUser(userId: currentUser.id)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case let .failure(error) = completion {
                            self?.isLoading = false
                            self?.errorMessage = "ユーザーデータの削除に失敗しました: \(error.localizedDescription)"
                            return
                        }

                        // Firestoreからの削除が成功したら、Firebaseアカウントを削除
                        firebaseUser.delete { [weak self] error in
                            DispatchQueue.main.async {
                                self?.isLoading = false

                                if let error = error {
                                    self?.errorMessage =
                                        "アカウントの削除に失敗しました: \(error.localizedDescription)"
                                } else {
                                    // 削除成功時は状態をリセット
                                    self?.user = nil
                                    self?.currentUser = nil
                                    self?.isAuthenticated = false
                                    self?.selectedAuthMethod = ""
                                    self?.needsUserNameInput = false

                                    // Google Sign Outも実行
                                    GIDSignIn.sharedInstance.signOut()
                                }
                            }
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        } else {
            // currentUserがない場合は直接Firebaseアカウントを削除
            firebaseUser.delete { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false

                    if let error = error {
                        self?.errorMessage = "アカウントの削除に失敗しました: \(error.localizedDescription)"
                    } else {
                        // 削除成功時は状態をリセット
                        self?.user = nil
                        self?.currentUser = nil
                        self?.isAuthenticated = false
                        self?.selectedAuthMethod = ""
                        self?.needsUserNameInput = false

                        // Google Sign Outも実行
                        GIDSignIn.sharedInstance.signOut()
                    }
                }
            }
        }
    }

    /// ユーザー名入力完了
    func completeUserNameInput() {
        needsUserNameInput = false
    }

    /// アプリ状態をリセット（未認証ユーザーのサインアウト用）
    func resetAppState() {
        UserDefaults.standard.set(false, forKey: "hasStartedWithoutAuth")
        // 認証状態の変更を通知（ContentViewの更新をトリガー）
        objectWillChange.send()
    }

    /// メール確認メールを送信
    func sendVerificationEmail() {
        guard let firebaseUser = user else {
            errorMessage = "ユーザー情報が取得できませんでした"
            return
        }

        if firebaseUser.isEmailVerified {
            errorMessage = "メールアドレスは既に確認済みです"
            return
        }

        isLoading = true
        errorMessage = nil

        firebaseUser.sendEmailVerification { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "確認メールの送信に失敗しました: \(error.localizedDescription)"
                } else {
                    // 成功メッセージを表示（エラーメッセージフィールドを一時的に使用）
                    print("✉️ 確認メールを送信しました")
                }
            }
        }
    }

    /// メール確認状態を更新
    func reloadUserAndCheckVerification() {
        guard let firebaseUser = user else { return }

        isLoading = true

        firebaseUser.reload { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "ユーザー情報の更新に失敗しました: \(error.localizedDescription)"
                    return
                }

                // メール確認状態を更新
                self?.isEmailVerified = firebaseUser.isEmailVerified

                if firebaseUser.isEmailVerified {
                    // メール確認完了
                    self?.needsEmailVerification = false
                    print("✅ メールアドレスが確認されました")

                    // 既存ユーザーをチェック
                    self?.checkExistingUserOrRequireNameInput(
                        uid: firebaseUser.uid, firebaseUser: firebaseUser)
                } else {
                    // まだ確認されていない場合
                    self?.errorMessage = "メールアドレスがまだ確認されていません。メール内のリンクをクリックしてください。"
                }
            }
        }
    }

    /// パスワードリセットメールを送信
    /// - Parameter email: リセットするメールアドレス
    func sendPasswordResetEmail(email: String) {
        guard !email.isEmpty else {
            errorMessage = "メールアドレスを入力してください"
            return
        }

        // 基本的なメールバリデーション
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            errorMessage = "有効なメールアドレスを入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    let nsError = error as NSError
                    let errorCode = nsError.code

                    // Firebase Authのエラーコードに応じたメッセージ
                    switch errorCode {
                    case 17011:  // FIRAuthErrorCodeUserNotFound
                        self?.errorMessage = "このメールアドレスは登録されていません"
                    case 17008:  // FIRAuthErrorCodeInvalidEmail
                        self?.errorMessage = "無効なメールアドレスです"
                    default:
                        self?.errorMessage = "パスワードリセットメールの送信に失敗しました: \(error.localizedDescription)"
                    }

                    print(
                        "❌ Password reset email failed: \(error.localizedDescription), code: \(errorCode)"
                    )
                } else {
                    print("✅ Password reset email sent successfully to \(email)")
                    // 成功時は特別なフラグを設定（ViewModelで処理）
                }
            }
        }
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

                // メール確認状態をチェック
                self?.isEmailVerified = firebaseUser.isEmailVerified

                if !firebaseUser.isEmailVerified {
                    // メール未確認の場合、確認待ち画面に遷移
                    print("⚠️ メールアドレスが未確認です")
                    self?.needsEmailVerification = true
                    self?.needsUserNameInput = false
                } else {
                    // メール認証成功 - handleAuthenticatedUserで処理される
                    print("✅ メール認証成功: \(firebaseUser.uid)")
                    self?.needsEmailVerification = false
                }
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

        Auth.auth().createUser(withEmail: email, password: password) {
            [weak self] authResult, error in
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

                // メール新規登録の場合、名前が既にあるのでFirestoreに直接保存
                print("メール新規登録成功: \(firebaseUser.uid), name: \(name)")
                self?.createUserInFirestore(uid: firebaseUser.uid, name: name)
            }
        }
    }

    /// メール・パスワードでサインアップ（名前入力は後で）
    /// - Parameters:
    ///   - email: メールアドレス
    ///   - password: パスワード
    func signUpWithEmailOnly(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "パスワードは6文字以上で入力してください"
            return
        }

        isLoading = true
        errorMessage = nil
        selectedAuthMethod = "email"  // 認証方式を設定

        Auth.auth().createUser(withEmail: email, password: password) {
            [weak self] authResult, error in
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

                // メール新規登録成功後、確認メールを送信
                print("🔥 Email signup success: \(firebaseUser.uid)")
                self?.needsEmailVerification = true
                self?.isEmailVerified = false
                self?.needsUserNameInput = false

                // 確認メールを送信
                firebaseUser.sendEmailVerification { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.errorMessage = "確認メールの送信に失敗しました: \(error.localizedDescription)"
                        } else {
                            print("✉️ 確認メールを送信しました")
                        }
                    }
                }
            }
        }
    }

    /// 匿名でサインイン
    func signInAnonymously() {
        isLoading = true
        errorMessage = nil

        Auth.auth().signInAnonymously { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = "匿名認証に失敗しました: \(error.localizedDescription)"
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    self?.errorMessage = "ユーザー情報の取得に失敗しました"
                    return
                }

                // 匿名ユーザー処理は handleAuthenticatedUser で自動的に実行される
                print("匿名ユーザーでサインインしました: \(firebaseUser.uid)")
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
                    // Google認証成功 - handleAuthenticatedUserで処理される
                    print("Google認証成功: \(firebaseUser.uid)")
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

    /// メール新規登録時にFirestoreにユーザーを作成
    /// - Parameters:
    ///   - uid: ユーザーID
    ///   - name: ユーザー名
    private func createUserInFirestore(uid: String, name: String) {
        UserService.shared.createUser(uid: uid, name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                    if case let .failure(error) = completion {
                        self?.errorMessage = "ユーザー情報の保存に失敗しました: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] (user: User) in
                    print("🔥 Email signup user created in Firestore: \(user.name)")
                    self?.currentUser = user
                    self?.needsUserNameInput = false  // 名前入力をスキップ
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

    func signInAnonymously() {
        isAuthenticated = true
        currentUser = User(id: "anonymous", name: "Guest User")
    }

    func signOut() {
        isAuthenticated = false
        currentUser = nil
    }

    func refreshCurrentUser() {}
    func updateCurrentUser(_ user: User) { currentUser = user }
    func clearError() { errorMessage = nil }
    func deleteAccount() {
        isAuthenticated = false
        currentUser = nil
    }
}

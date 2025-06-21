// Services/AuthService.swift
import Combine
import Firebase
import FirebaseAuth
import GoogleSignIn

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var user: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isAnonymous: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAuthStateListener()
        // アプリ起動時に匿名ログインを実行
        // signInAnonymously()
    }

    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            DispatchQueue.main.async {
                self?.user = firebaseUser
                self?.isAuthenticated = firebaseUser != nil
                self?.isAnonymous = firebaseUser?.isAnonymous ?? false

                if let user = firebaseUser {
                    // Firebase認証済みユーザーの場合
                    if !user.isAnonymous {
                        self?.loadCurrentUser(uid: user.uid)
                    } else {
                        // 匿名ユーザーの場合、Firestoreにユーザー情報はないので currentUser はクリア
                        self?.currentUser = nil
                    }
                } else {
                    // ユーザーがいない場合（サインアウト後や初回起動時など）
                    self?.currentUser = nil
                    // ここで、もしFirebaseにユーザーが存在しない場合は匿名ログインを試みる
                    // ただし、既に認証処理中でないことを確認します
                    if !(self?.isLoading ?? false) {
                        self?.signInAnonymouslyIfNeeded()
                    }
                }
                // 認証状態が確定したためローディングを終了
                self?.isLoading = false
            }
        }
    }

    private func signInAnonymouslyIfNeeded() {
        guard !isAuthenticated else { return }

        isLoading = true
        errorMessage = nil

        Auth.auth().signInAnonymously { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage =
                        "匿名ログインに失敗しました: \(error.localizedDescription)"
                    print("匿名ログインエラー: \(error)")
                } else if authResult?.user != nil {
                    print("匿名ログインが完了しました")
                }
            }
        }
    }

    private func loadCurrentUser(uid: String) {
        firestoreService.getUser(uid: uid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: {
                    [weak self] (completion: Subscribers.Completion<Error>) in
                    if case .failure(let error) = completion {
                        print(
                            "Firestoreからのユーザー情報取得エラー: \(error.localizedDescription)"
                        )
                        // エラーメッセージは設定しない（新規ユーザーの場合は正常な動作）
                    }
                },
                receiveValue: { [weak self] (user: User?) in
                    self?.currentUser = user
                    if user != nil {
                        print("Firestoreからユーザー情報を正常に取得しました")
                    }
                }
            )
            .store(in: &cancellables)
    }

    func refreshCurrentUser() {
        guard let uid = user?.uid, !isAnonymous else { return }
        loadCurrentUser(uid: uid)
    }

    // MARK: - Anonymous Authentication

    func signInAnonymously() {
        // 既に認証済みの場合は何もしない
        if isAuthenticated { return }

        isLoading = true
        errorMessage = nil

        Auth.auth().signInAnonymously { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage =
                        "匿名ログインに失敗しました: \(error.localizedDescription)"
                    print("匿名ログインエラー: \(error)")
                } else if authResult?.user != nil {
                    print("匿名ログインが完了しました")
                }
            }
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene,
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

        // Configure Google Sign In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        isLoading = true
        errorMessage = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) {
            [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage =
                        "Google認証に失敗しました: \(error.localizedDescription)"
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

                // 匿名ユーザーとGoogle認証をリンク
                if let currentUser = Auth.auth().currentUser,
                    currentUser.isAnonymous
                {
                    self?.linkAnonymousWithGoogle(
                        credential: credential,
                        googleUser: user
                    )
                } else {
                    // 通常のGoogle認証
                    self?.signInWithCredential(
                        credential: credential,
                        googleUser: user
                    )
                }
            }
        }
    }

    private func linkAnonymousWithGoogle(
        credential: AuthCredential,
        googleUser: GIDGoogleUser
    ) {
        guard let currentUser = Auth.auth().currentUser else { return }

        currentUser.link(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    // エラーの詳細を確認
                    let nsError = error as NSError

                    // エラーコード17007は「ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL」を意味する
                    // これは、このGoogleアカウントが既に他のFirebaseユーザーに紐づいている場合
                    if nsError.code
                        == AuthErrorCode.accountExistsWithDifferentCredential
                        .rawValue
                    {
                        print("Googleアカウントが既に他のユーザーに紐づいています。既存ユーザーでログインします。")

                        // 既存のユーザーでログインを試行
                        self?.signInWithExistingGoogleAccount(
                            credential: credential,
                            googleUser: googleUser
                        )
                    } else if nsError.code
                        == AuthErrorCode.credentialAlreadyInUse.rawValue
                    {
                        // エラーコード17025は「CREDENTIAL_ALREADY_IN_USE」を意味する
                        // この場合も既存のユーザーでログインを試行
                        print("Googleアカウントが既に使用されています。既存ユーザーでログインします。")
                        self?.signInWithExistingGoogleAccount(
                            credential: credential,
                            googleUser: googleUser
                        )
                    } else {
                        self?.errorMessage =
                            "アカウントのリンクに失敗しました: \(error.localizedDescription)"
                    }
                } else if let firebaseUser = authResult?.user {
                    let displayName = googleUser.profile?.name ?? "Google User"
                    print("匿名ユーザーとGoogleアカウントをリンクしました: \(displayName)")
                    self?.saveUserToFirestore(
                        uid: firebaseUser.uid,
                        name: displayName
                    )
                }
            }
        }
    }

    // 既存のGoogleアカウントでログイン
    private func signInWithExistingGoogleAccount(
        credential: AuthCredential,
        googleUser: GIDGoogleUser
    ) {
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage =
                        "既存アカウントでのログインに失敗しました: \(error.localizedDescription)"
                } else if let firebaseUser = authResult?.user {
                    let displayName = googleUser.profile?.name ?? "Google User"
                    print("既存のGoogleアカウントでログインしました: \(displayName)")

                    // 既存ユーザーの場合、Firestoreからユーザー情報を取得
                    if authResult?.additionalUserInfo?.isNewUser == false {
                        self?.loadCurrentUser(uid: firebaseUser.uid)
                    } else {
                        // 新規ユーザーの場合（通常は発生しないが念のため）
                        self?.saveUserToFirestore(
                            uid: firebaseUser.uid,
                            name: displayName
                        )
                    }
                }
            }
        }
    }

    private func signInWithCredential(
        credential: AuthCredential,
        googleUser: GIDGoogleUser
    ) {
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage =
                        "認証に失敗しました: \(error.localizedDescription)"
                } else if let firebaseUser = authResult?.user {
                    // 新規ユーザーの場合、Firestoreにユーザー情報を保存
                    if authResult?.additionalUserInfo?.isNewUser == true {
                        let displayName =
                            googleUser.profile?.name ?? "Google User"
                        print("新規ユーザーを検出: \(displayName)")
                        self?.saveUserToFirestore(
                            uid: firebaseUser.uid,
                            name: displayName
                        )
                    } else {
                        print("既存ユーザーのサインイン")
                        // 既存ユーザーの場合、Firestoreからユーザー情報を取得
                        self?.loadCurrentUser(uid: firebaseUser.uid)
                    }
                }
            }
        }
    }

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

    // MARK: - User Management

    private func saveUserToFirestore(uid: String, name: String) {
        print("Firestoreにユーザー情報を保存開始: \(name)")

        firestoreService.createUser(uid: uid, name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage =
                            "ユーザー情報の保存に失敗しました: \(error.localizedDescription)"
                        print("Firestore保存エラー: \(error)")
                    } else {
                        print("Firestoreへのユーザー情報保存が完了しました")
                        // 保存成功後、最新のユーザー情報を再取得
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self?.refreshCurrentUser()
                        }
                    }
                },
                receiveValue: { [weak self] user in
                    print(
                        "作成されたユーザー: \(user.name), ID: \(user.id), 招待コード: \(user.inviteCode)"
                    )
                    // 直接currentUserを設定
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)
    }

    // 現在のユーザーID取得
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }

    // Google認証が完了しているかチェック
    var isGoogleAuthenticated: Bool {
        return isAuthenticated && !isAnonymous
    }

    // 現在のユーザー情報更新
    func updateCurrentUser(_ user: User) {
        guard isGoogleAuthenticated else { return }

        firestoreService.updateUser(user)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] updatedUser in
                    self?.currentUser = updatedUser
                }
            )
            .store(in: &cancellables)
    }

    // エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
}

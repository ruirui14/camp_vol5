import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @EnvironmentObject private var viewModelFactory: ViewModelFactory
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                _ = print(
                    """
                    🔥 ContentView - isLoading: \(authenticationManager.isLoading), \
                    needsUserNameInput: \(authenticationManager.needsUserNameInput), \
                    isAuthenticated: \(authenticationManager.isAuthenticated), \
                    currentUser: \(authenticationManager.currentUser != nil), \
                    needsEmailVerification: \(authenticationManager.needsEmailVerification)
                    """
                )

                if authenticationManager.needsUserNameInput {
                    // ユーザー名入力が必要な場合
                    _ = print("🔥 Showing UserNameInputView")
                    UserNameInputView(
                        selectedAuthMethod: mapAuthMethod(
                            authenticationManager.selectedAuthMethod),
                        factory: viewModelFactory
                    )
                } else if authenticationManager.isAuthenticated
                    && authenticationManager.currentUser != nil
                {
                    // ログイン済みかつユーザー情報がある場合
                    _ = print("🔥 Showing ListHeartBeatsView")
                    ListHeartBeatsView()
                } else {
                    // 認証されていない場合、またはユーザー情報がない場合は認証画面を表示
                    // メール確認待ち状態も含む
                    _ = print(
                        """
                        🔥 Showing AuthView - isAuthenticated: \(authenticationManager.isAuthenticated), \
                        currentUser: \(authenticationManager.currentUser != nil), \
                        needsEmailVerification: \(authenticationManager.needsEmailVerification)
                        """
                    )
                    AuthView(
                        onStartWithoutAuth: {
                            // このクロージャは現在使用されていない（匿名サインインに置き換えられた）
                        },
                        factory: viewModelFactory
                    )
                }
            }
        }
        .id(
            "\(authenticationManager.needsUserNameInput)-\(authenticationManager.currentUser?.id ?? "none")"
        )
        .onChange(of: authenticationManager.isAuthenticated) { _, isAuthenticated in
            // 認証状態が失われた場合（アカウント削除やサインアウト）、NavigationStackをクリア
            if !isAuthenticated {
                navigationPath = NavigationPath()
            }
        }
    }

    private func mapAuthMethod(_ method: String) -> SelectedAuthMethod {
        switch method {
        case "google":
            return .google
        case "email":
            return .email
        case "anonymous":
            return .anonymous
        default:
            return .anonymous
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            Text("Heart Beat Monitor")
                .font(.largeTitle)
                .fontWeight(.bold)

            ProgressView("アプリを準備中...")
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

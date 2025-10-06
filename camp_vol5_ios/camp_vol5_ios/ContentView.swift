import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @State private var navigationPath = NavigationPath()
    @State private var showSplash = true

    var body: some View {
        ZStack {
            NavigationStack(path: $navigationPath) {
                Group {
                    let _ = print(
                        "🔥 ContentView - isLoading: \(authenticationManager.isLoading), needsUserNameInput: \(authenticationManager.needsUserNameInput), isAuthenticated: \(authenticationManager.isAuthenticated), currentUser: \(authenticationManager.currentUser != nil)"
                    )

                    if authenticationManager.isAuthenticated && authenticationManager.currentUser != nil
                    {
                        // ログイン済みかつユーザー情報がある場合
                        let _ = print("🔥 Showing ListHeartBeatsView")
                        ListHeartBeatsView()
                    } else {
                        // 認証されていない場合、またはユーザー情報がない場合は認証画面を表示
                        let _ = print(
                            "🔥 Showing AuthView - isAuthenticated: \(authenticationManager.isAuthenticated), currentUser: \(authenticationManager.currentUser != nil)"
                        )
                        AuthView(onStartWithoutAuth: {
                            // このクロージャは現在使用されていない（匿名サインインに置き換えられた）
                        })
                    }
                }
                .navigationDestination(for: String.self) { destination in
                    if destination == "userNameInput" {
                        let _ = print("🔥 Showing UserNameInputView via navigation")
                        UserNameInputView(
                            selectedAuthMethod: mapAuthMethod(authenticationManager.selectedAuthMethod)
                        )
                    }
                }
            }
            .onChange(of: authenticationManager.needsUserNameInput) { needsInput in
                if needsInput {
                    navigationPath.append("userNameInput")
                } else {
                    // 名前入力完了時はパスをクリア
                    if !navigationPath.isEmpty {
                        navigationPath.removeLast()
                    }
                }
            }

            if showSplash {
                SplashView(isActive: $showSplash)
                    .transition(.opacity)
                    .zIndex(1)
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

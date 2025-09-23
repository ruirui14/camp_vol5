import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @State private var hasStartedWithoutAuth = UserDefaults.standard.bool(forKey: "hasStartedWithoutAuth")

    var body: some View {
        Group {
            if authenticationManager.isLoading {
                // 認証処理中の場合はローディング画面を表示
                LoadingView()
            } else if authenticationManager.isAuthenticated {
                // ログイン済みの場合
                if authenticationManager.currentUser != nil {
                    // ユーザー情報がある場合
                    ListHeartBeatsView()
                } else {
                    // ユーザー情報読み込み中
                    LoadingView()
                }
            } else if hasStartedWithoutAuth {
                // 認証なしで開始した場合
                ListHeartBeatsView()
            } else {
                // 未認証の場合は認証画面を表示
                AuthView(onStartWithoutAuth: {
                    hasStartedWithoutAuth = true
                    UserDefaults.standard.set(true, forKey: "hasStartedWithoutAuth")
                })
            }
        }
        .animation(
            .easeInOut(duration: 1.0),
            value: authenticationManager.isAuthenticated || hasStartedWithoutAuth
        )
        .onChange(of: authenticationManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // ログイン時: 認証なし開始フラグをリセット
                hasStartedWithoutAuth = false
                UserDefaults.standard.set(false, forKey: "hasStartedWithoutAuth")
            } else {
                // サインアウト時: 認証なし開始フラグもリセットしてログイン画面を表示
                hasStartedWithoutAuth = false
                UserDefaults.standard.set(false, forKey: "hasStartedWithoutAuth")
            }
        }
        .onReceive(authenticationManager.objectWillChange) { _ in
            // AuthenticationManagerの状態変更時にUserDefaultsから最新の値を読み込み
            let currentValue = UserDefaults.standard.bool(forKey: "hasStartedWithoutAuth")
            if hasStartedWithoutAuth != currentValue {
                hasStartedWithoutAuth = currentValue
            }
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


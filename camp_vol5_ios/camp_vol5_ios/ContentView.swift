import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager

    var body: some View {
        Group {
            if authenticationManager.isAuthenticated {
                // 1. 匿名ユーザ
                // 2. 匿名ユーザではなく、カレントユーザを読み込んでいる
                if (authenticationManager.isAnonymous && authenticationManager.currentUser == nil)
                    || !authenticationManager.isAnonymous
                        && (authenticationManager.currentUser != nil)
                {
                    ListHeartBeatsView()
                }
            } else if authenticationManager.isLoading {
                // 認証中の場合はローディング画面を表示
                LoadingView()
            } else {
                // 認証に失敗した場合のエラー画面
                ErrorView()
            }
        }
        .animation(
            .easeInOut(duration: 1.0),
            value: authenticationManager.isAuthenticated
        )
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

struct ErrorView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("接続エラー")
                .font(.title)
                .fontWeight(.bold)

            if let errorMessage = authenticationManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Button("再試行") {
                authenticationManager.clearError()
                authenticationManager.signInAnonymously()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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

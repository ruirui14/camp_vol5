import SwiftUI

struct ContentView2: View {
    @StateObject private var authService = AuthService.shared

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // 認証済み（匿名またはGoogle）の場合はメインアプリを表示
                if authService.isAuthenticated {
                    ListHeartBeatsView()
                        .environmentObject(authService)
                }
            } else if authService.isLoading {
                // 認証中の場合はローディング画面を表示
                LoadingView()
            } else {
                // 認証に失敗した場合のエラー画面
                ErrorView()
            }
        }
        .animation(
            .easeInOut(duration: 1.0),
            value: authService.isAuthenticated
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
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("接続エラー")
                .font(.title)
                .fontWeight(.bold)

            if let errorMessage = AuthService.shared.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Button("再試行") {
                AuthService.shared.clearError()
                AuthService.shared.signInAnonymously()
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

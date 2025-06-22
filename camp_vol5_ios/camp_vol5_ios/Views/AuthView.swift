import SwiftUI

struct AuthView: View {
    @StateObject private var authService = AuthService.shared

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // App Logo/Title Section
            VStack(spacing: 20) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)

                Text("Heart Beat Monitor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("リアルタイムで心拍数を\n共有・モニタリング")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Authentication Section
            VStack(spacing: 20) {
                Text("Googleアカウントでサインイン")
                    .font(.headline)
                    .foregroundColor(.secondary)

                // Google Sign In Button
                Button(action: {
                    authService.signInWithGoogle()
                }) {
                    HStack(spacing: 12) {
                        if authService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "globe")
                                .font(.title2)
                        }

                        Text(
                            authService.isLoading ? "サインイン中..." : "Googleでサインイン"
                        )
                        .font(.headline)
                        .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(authService.isLoading)
                .scaleEffect(authService.isLoading ? 0.95 : 1.0)
                .animation(
                    .easeInOut(duration: 0.1),
                    value: authService.isLoading
                )

                // Error Message
                if let errorMessage = authService.errorMessage {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.callout)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)

                        Button("再試行") {
                            authService.clearError()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }

                // Features Preview
                VStack(spacing: 12) {
                    Divider()
                        .padding(.vertical, 8)

                    Text("主な機能")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "heart.fill", text: "リアルタイム心拍モニタリング")
                        FeatureRow(icon: "qrcode", text: "QRコードで簡単フォロー")
                        FeatureRow(icon: "person.2.fill", text: "友達の心拍数を共有")
                        FeatureRow(icon: "bell.fill", text: "リアルタイム通知")
                    }
                }
            }

            Spacer()

            // Footer
            Text("© 2024 Heart Beat Monitor")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
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

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}

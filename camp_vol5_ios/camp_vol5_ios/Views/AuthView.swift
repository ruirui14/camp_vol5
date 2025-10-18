import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @EnvironmentObject private var viewModelFactory: ViewModelFactory
    @StateObject private var viewModel: AuthViewModel

    let onStartWithoutAuth: () -> Void

    init(
        onStartWithoutAuth: @escaping () -> Void,
        factory: ViewModelFactory
    ) {
        self.onStartWithoutAuth = onStartWithoutAuth
        self._viewModel = StateObject(
            wrappedValue: factory.makeAuthViewModel()
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [
                        Color(.systemIndigo).opacity(0.1),
                        Color(.systemBlue).opacity(0.05),
                        Color(.systemBackground),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        VStack(spacing: 24) {
                            Spacer(minLength: 60)

                            // App Icon and Animation
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.red.opacity(0.2), Color.pink.opacity(0.1),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                        .scaleEffect(viewModel.animateContent ? 1.0 : 0.8)
                                        .animation(
                                            .easeInOut(duration: 0.8).repeatForever(
                                                autoreverses: true),
                                            value: viewModel.animateContent
                                        )

                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundColor(.red)
                                        .scaleEffect(viewModel.animateContent ? 1.1 : 1.0)
                                        .animation(
                                            .easeInOut(duration: 1.0).repeatForever(
                                                autoreverses: true),
                                            value: viewModel.animateContent
                                        )
                                }

                                // Authentication Buttons
                                VStack(spacing: 20) {
                                    VStack(spacing: 16) {
                                        Text("始めましょう")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)

                                        Text("アカウントを作成するか、既存のアカウントでサインインしてください")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                    }

                                    VStack(spacing: 8) {
                                        Text("狂愛")
                                            .font(
                                                .system(size: 32, weight: .bold, design: .rounded)
                                            )
                                            .multilineTextAlignment(.center)
                                            .opacity(viewModel.animateContent ? 1.0 : 0.7)

                                        Text("推しの心拍数を感じよう")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                            .opacity(viewModel.animateContent ? 1.0 : 0.5)
                                    }
                                }
                            }
                            .frame(height: geometry.size.height * 0.5)

                            // Start Without Auth Button
                            VStack(spacing: 12) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        viewModel.signInAnonymously()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "play.circle")
                                            .font(.title2)
                                        Text("はじめる")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundColor(.accent)
                                    .background(Color.accent.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal, 24)

                                Text("認証なしでアプリを体験")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Divider()
                                    .padding(.horizontal, 24)

                                Text("または")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)

                                // Email Authentication Button
                                Button(action: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        viewModel.showEmailAuthModal()
                                    }
                                }) {
                                    AuthButton(
                                        icon: "envelope.fill",
                                        title: "メールアドレスで続ける",
                                        subtitle: "メールとパスワードで新規作成・ログイン",
                                        color: .green,
                                        isSelected: viewModel.selectedAuthMethod == .email
                                    )
                                }

                                // Google Authentication Button
                                Button(action: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        viewModel.signInWithGoogle()
                                    }
                                }) {
                                    AuthButton(
                                        icon: "globe",
                                        title: "Googleで続ける",
                                        subtitle: "Googleアカウントで簡単ログイン",
                                        color: .blue,
                                        isSelected: viewModel.selectedAuthMethod == .google,
                                        isLoading: viewModel.isGoogleLoading
                                    )
                                }
                                .disabled(viewModel.isLoading)
                            }
                            .padding(.horizontal, 24)
                        }

                        // Error Display
                        if let errorMessage = viewModel.errorMessage {
                            ErrorCard(message: errorMessage) {
                                viewModel.clearError()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }

                        Spacer(minLength: 20)

                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .sheet(
            isPresented: $viewModel.showEmailAuth,
            onDismiss: {
                viewModel.dismissEmailAuth()
            }
        ) {
            EmailAuthView(factory: viewModelFactory)
                .environmentObject(authenticationManager)
                .environmentObject(viewModelFactory)
        }
    }
}

// MARK: - Supporting Views

struct AuthButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isSelected: Bool
    let isLoading: Bool

    init(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        isSelected: Bool = false,
        isLoading: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.isSelected = isSelected
        self.isLoading = isLoading
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon Section
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(color)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
            }

            // Text Section
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(isSelected ? 1.0 : 0.6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.05),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? color.opacity(0.5) : Color.clear,
                    lineWidth: 2
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ErrorCard: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text("エラーが発生しました")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button("閉じる", action: onDismiss)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthenticationManager()
        let factory = ViewModelFactory(
            authenticationManager: authManager,
            userService: UserService.shared,
            heartbeatService: HeartbeatService.shared,
            vibrationService: VibrationService.shared
        )
        return AuthView(onStartWithoutAuth: {}, factory: factory)
            .environmentObject(authManager)
            .environmentObject(factory)
    }
}

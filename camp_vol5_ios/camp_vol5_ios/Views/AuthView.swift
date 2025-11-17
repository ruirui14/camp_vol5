// AuthView.swift
// ログイン画面 - モダンでキュートなデザイン
// 心拍数をテーマにしたアニメーションと、グラスモーフィズム効果を採用

import AuthenticationServices
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
        ZStack {
            // デフォルトのグラデーション背景
            MainAccentGradient()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 30)

                    // ヒーローセクション
                    VStack(spacing: 24) {
                        // ハートアニメーション
                        HeartbeatAnimation(isAnimating: viewModel.animateContent)
                            .frame(width: 100, height: 100)

                        // タイトル
                        VStack(spacing: 8) {
                            Text("狂愛")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color.white.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                                .scaleEffect(viewModel.animateContent ? 1.0 : 0.95)

                            Text("推しの心拍数を感じよう")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                        }
                        .opacity(viewModel.animateContent ? 1.0 : 0.7)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: viewModel.animateContent
                        )
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 20)

                    // 認証ボタンセクション
                    VStack(spacing: 16) {
                        // メール認証フォーム（常に表示）
                        emailAuthFormView

                        // 区切り線
                        HStack {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(0.4))
                                .frame(height: 1)
                            Text("または")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.white.opacity(0.4))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)

                        // 匿名認証ボタン（標準デザイン）
                        AnonymousSignInButton(
                            isLoading: viewModel.isLoading
                                && viewModel.selectedAuthMethod == .anonymous
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                viewModel.signInAnonymously()
                            }
                        }
                        .disabled(viewModel.isLoading)

                        // Google認証ボタン（標準デザイン）
                        GoogleSignInButton(
                            isLoading: viewModel.isGoogleLoading
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                viewModel.signInWithGoogle()
                            }
                        }
                        .disabled(viewModel.isLoading)

                        // Apple認証ボタン（標準デザイン）
                        AppleSignInButton(
                            isLoading: viewModel.isAppleLoading
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                viewModel.signInWithApple()
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // エラー表示
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage) {
                            viewModel.clearError()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $viewModel.showPasswordReset) {
            passwordResetView
        }
    }

    // MARK: - Email Auth Form View

    private var emailAuthFormView: some View {
        VStack(spacing: 18) {
            if viewModel.needsEmailVerification {
                emailVerificationView
            } else {
                authenticationFormView
            }
        }
    }

    private var emailVerificationView: some View {
        VStack(spacing: 16) {
            // アイコン
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FFD93D"), Color(hex: "F9CA24")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // メッセージ
            VStack(spacing: 8) {
                Text("メールアドレスを確認してください")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("登録したメールアドレスに確認メールを送信しました。")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            // ボタン
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.checkEmailVerification()
                }) {
                    HStack(spacing: 6) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.callout)
                        }
                        Text("確認完了")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.25))
                    )
                    .foregroundColor(.white)
                }
                .disabled(viewModel.isLoading)

                Button(action: {
                    viewModel.sendVerificationEmail()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.callout)
                        Text("再送信")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.25))
                    )
                    .foregroundColor(.white)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding(.horizontal, 8)
    }

    private var authenticationFormView: some View {
        VStack(spacing: 16) {
            // フォーム
            VStack(spacing: 12) {
                // メールアドレス
                GlassTextField(
                    icon: "envelope",
                    placeholder: "メールアドレス",
                    text: $viewModel.email,
                    keyboardType: .emailAddress
                )

                // パスワード
                GlassSecureField(
                    icon: "lock",
                    placeholder: "パスワード",
                    text: $viewModel.password,
                    showPassword: $viewModel.showPassword
                )

                // パスワード確認（新規登録時のみ）
                if viewModel.isSignUp {
                    GlassSecureField(
                        icon: "lock.fill",
                        placeholder: "パスワード（確認）",
                        text: $viewModel.confirmPassword,
                        showPassword: $viewModel.showConfirmPassword
                    )
                    .transition(.opacity)

                    // パスワード不一致の警告
                    if !viewModel.confirmPassword.isEmpty
                        && viewModel.password != viewModel.confirmPassword
                    {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(Color(hex: "FF6B6B"))
                            Text("パスワードが一致しません")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .transition(.opacity)
                    }
                }
            }

            // ボタンセクション
            VStack(spacing: 12) {
                // メイン認証ボタン
                Button(action: {
                    viewModel.signInWithEmail()
                }) {
                    HStack(spacing: 12) {
                        if viewModel.isEmailLoading {
                            ProgressView()
                                .tint(Color(hex: "4ECDC4"))
                        } else {
                            Image(
                                systemName: viewModel.isSignUp
                                    ? "person.badge.plus" : "arrow.right.circle.fill"
                            )
                            .font(.title2)
                            .foregroundColor(.accent)
                        }

                        Text(
                            viewModel.isEmailLoading
                                ? (viewModel.isSignUp ? "アカウント作成中..." : "サインイン中...")
                                : (viewModel.isSignUp ? "アカウント作成" : "サインイン")
                        )
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.text)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "f2f2f2"))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                }
                .disabled(viewModel.isLoading || !viewModel.isFormValid)
                .opacity(viewModel.isFormValid ? 1.0 : 0.6)

                // サブボタン（小さめ）
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            viewModel.toggleAuthMode()
                        }
                    }) {
                        Text(viewModel.isSignUp ? "既存のアカウントでサインイン" : "新しいアカウントを作成")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .underline()
                    }

                    if !viewModel.isSignUp {
                        Button(action: {
                            viewModel.showPasswordResetSheet()
                        }) {
                            Text("パスワードを忘れた")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                                .underline()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Password Reset View

    private var passwordResetView: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                MainAccentGradient()

                ScrollView {
                    VStack(spacing: 28) {
                        if viewModel.passwordResetSent {
                            passwordResetSuccessView
                        } else {
                            passwordResetFormView
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.dismissPasswordReset()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
            }
        }
    }

    private var passwordResetFormView: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 40)

            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: "key.fill")
                    .font(.system(size: 54, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF9A8B"), Color(hex: "FF6A88")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // タイトル
            VStack(spacing: 16) {
                Text("パスワードをリセット")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

                Text("登録したメールアドレスを入力してください。\nパスワードリセット用のリンクを送信します。")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }

            // メールアドレス入力
            GlassTextField(
                icon: "envelope",
                placeholder: "メールアドレス",
                text: $viewModel.resetEmail,
                keyboardType: .emailAddress
            )

            // 送信ボタン
            Button(action: {
                viewModel.sendPasswordResetEmail()
            }) {
                HStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color(hex: "4ECDC4"))
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(.accent)
                    }

                    Text(viewModel.isLoading ? "送信中..." : "リセットメールを送信")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.text)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "f2f2f2"))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
            }
            .disabled(viewModel.isLoading || viewModel.resetEmail.isEmpty)
            .opacity((viewModel.resetEmail.isEmpty || viewModel.isLoading) ? 0.6 : 1.0)

            // エラーメッセージ
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    viewModel.clearError()
                }
            }
        }
    }

    private var passwordResetSuccessView: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 60)

            // 成功アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "4ECDC4"), Color(hex: "44A08D")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // タイトル
            VStack(spacing: 16) {
                Text("メールを送信しました")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

                Text("パスワードリセット用のリンクを\n\(viewModel.resetEmail)\nに送信しました。")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }

            // 注意事項
            GlassInfoCard(
                icon: "info.circle.fill",
                iconColor: Color(hex: "4ECDC4"),
                title: "メールが届かない場合",
                items: [
                    "迷惑メールフォルダを確認してください",
                    "メールアドレスが正しいか確認してください",
                    "数分待ってから再度お試しください",
                ]
            )

            // 完了ボタン
            Button(action: {
                viewModel.dismissPasswordReset()
            }) {
                Text("完了")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(.ultraThinMaterial.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    )
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - ハートビートアニメーション

struct HeartbeatAnimation: View {
    let isAnimating: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            // 外側の円（波紋効果）
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .scaleEffect(pulse ? 1.8 : 1.0)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.5),
                        value: pulse
                    )
            }

            // グラスモーフィズム背景
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .pink.opacity(0.5), radius: 20, x: 0, y: 10)

            // ハートアイコン
            Image(systemName: "heart.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(Color.accent)
                .scaleEffect(pulse ? 1.15 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: pulse
                )
                .shadow(color: Color.accent.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .onAppear {
            pulse = true
        }
    }
}

// MARK: - グラスモーフィズムボタン

struct GlassButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isSelected: Bool = false
    var isLoading: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 16) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    if isLoading {
                        ProgressView()
                            .tint(color)
                    } else {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    }
                }

                // テキスト
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.35 : 0.25),
                                Color.white.opacity(isSelected ? 0.25 : 0.15),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.3),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            // swiftlint:disable multiline_arguments
            .shadow(
                color: color.opacity(0.25), radius: isSelected ? 15 : 10, x: 0,
                y: isSelected ? 8 : 5)
            // swiftlint:enable multiline_arguments
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - エラーバナー

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(hex: "FF6B6B"))
                .font(.title3)

            Text(message)
                .font(.callout)
                .foregroundColor(.white)
                .fontWeight(.medium)
                .lineLimit(3)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.title3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FF6B6B").opacity(0.4),
                            Color(hex: "EE5A6F").opacity(0.3),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "FF6B6B").opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color(hex: "FF6B6B").opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Googleサインインボタン

struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(Color(hex: "4285F4"))
                } else {
                    Image("GoogleLogo")
                        .padding(.trailing, -15)
                }

                Text("Googleでサインイン")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "3c4043"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(hex: "f2f2f2"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Appleサインインボタン

struct AppleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Text("Appleでサインイン")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - 匿名サインインボタン

struct AnonymousSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                }

                Text("匿名ではじめる")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "3c4043"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(hex: "f2f2f2"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
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

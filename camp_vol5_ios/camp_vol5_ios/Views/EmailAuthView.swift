// Views/EmailAuthView.swift
// メール・パスワード認証用のSwiftUIビュー - モダンでキュートなデザイン
// サインインとサインアップ機能を含む
// OnboardingViewとの統合対応

import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: EmailAuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDismissConfirmation = false

    init(factory: ViewModelFactory) {
        self._viewModel = StateObject(
            wrappedValue: factory.makeEmailAuthViewModel()
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                MainAccentGradient()

                // 浮遊する円（背景装飾）
                FloatingCircles()

                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.needsEmailVerification {
                            emailVerificationView
                        } else {
                            authenticationFormView
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if viewModel.needsEmailVerification {
                            showDismissConfirmation = true
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("戻る")
                        }
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .alert("メール確認が完了していません", isPresented: $showDismissConfirmation) {
                Button("戻らずに確認する", role: .cancel) {}
                Button("キャンセルして戻る", role: .destructive) {
                    authenticationManager.signOut()
                    dismiss()
                }
            } message: {
                Text("メールアドレスの確認が完了していません。戻る場合、作成したアカウントからサインアウトされます。")
            }
        }
        .sheet(isPresented: $viewModel.showPasswordReset) {
            PasswordResetView(viewModel: viewModel)
        }
    }

    // MARK: - Email Verification View

    private var emailVerificationView: some View {
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

                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 54, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD93D"), Color(hex: "F9CA24")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // タイトルとメッセージ
            VStack(spacing: 16) {
                Text("メールアドレスを確認してください")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

                Text("登録したメールアドレスに確認メールを送信しました。\nメール内のリンクをクリックして、メールアドレスを確認してください。")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            // ボタンセクション
            VStack(spacing: 14) {
                // 確認完了ボタン
                Button(action: {
                    viewModel.checkEmailVerification()
                }) {
                    HStack(spacing: 10) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                        }

                        Text("確認完了")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
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
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .shadow(color: Color(hex: "4ECDC4").opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .disabled(viewModel.isLoading)

                // 確認メール再送信ボタン
                Button(action: {
                    viewModel.sendVerificationEmail()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("確認メールを再送信")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                }
                .disabled(viewModel.isLoading)
            }

            // 注意事項
            GlassInfoCard(
                icon: "info.circle.fill",
                iconColor: Color(hex: "FFD93D"),
                title: "メールが届かない場合",
                items: [
                    "迷惑メールフォルダを確認してください",
                    "メールアドレスが正しいか確認してください",
                    "確認メールの再送信をお試しください",
                ]
            )

            // エラーメッセージ
            if let errorMessage = viewModel.errorMessage {
                ErrorMessageCard(message: errorMessage) {
                    viewModel.clearError()
                }
            }
        }
    }

    // MARK: - Authentication Form View

    private var authenticationFormView: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 30)

            // ヘッダーアイコン
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
                    .frame(width: 100, height: 100)
                    .scaleEffect(viewModel.animateForm ? 1.0 : 0.9)
                    .shadow(color: .white.opacity(0.3), radius: 15, x: 0, y: 8)

                Image(systemName: "envelope.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD93D"), Color(hex: "F9CA24")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: viewModel.animateForm)

            // タイトル
            VStack(spacing: 10) {
                Text(viewModel.authModeTitle)
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

                Text(viewModel.authModeSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .opacity(viewModel.animateForm ? 1.0 : 0.8)

            // フォーム
            VStack(spacing: 18) {
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

                if viewModel.isSignUp {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "FFD93D"))
                        Text("パスワードは6文字以上で入力してください")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .transition(.opacity)
                }
            }
            .opacity(viewModel.animateForm ? 1.0 : 0.6)

            // ボタンセクション
            VStack(spacing: 16) {
                // メイン認証ボタン
                Button(action: {
                    viewModel.signInWithEmail()
                }) {
                    HStack(spacing: 10) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(
                                systemName: viewModel.isSignUp
                                    ? "person.badge.plus" : "arrow.right.circle.fill"
                            )
                            .font(.title3)
                        }

                        Text(viewModel.primaryButtonTitle)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
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
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .shadow(color: Color(hex: "4ECDC4").opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .disabled(viewModel.isLoading || !viewModel.isFormValid)
                .opacity(viewModel.isFormValid ? 1.0 : 0.6)

                // モード切り替えボタン
                Button(action: {
                    viewModel.toggleAuthMode()
                }) {
                    Text(viewModel.toggleModeText)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .underline()
                }

                // パスワードを忘れた場合
                if !viewModel.isSignUp {
                    Button(action: {
                        viewModel.showPasswordResetSheet()
                    }) {
                        Text("パスワードをお忘れですか？")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                            .underline()
                    }
                }
            }

            // エラーメッセージ
            if let errorMessage = viewModel.errorMessage {
                ErrorMessageCard(message: errorMessage) {
                    viewModel.clearError()
                }
            }

            Spacer()
        }
    }
}

// MARK: - Glass TextField

struct GlassTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))

            TextField(placeholder, text: $text)
                .textContentType(.emailAddress)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .foregroundColor(.white)
                .tint(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.15),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .shadow(color: Color.white.opacity(0.5), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Glass Secure Field

struct GlassSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))

            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textContentType(.password)
            .foregroundColor(.white)
            .tint(.white)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPassword.toggle()
                }
            }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.15),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .shadow(color: Color.white.opacity(0.5), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Glass Info Card

struct GlassInfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let items: [String]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.white.opacity(0.7))
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(iconColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Error Message Card

struct ErrorMessageCard: View {
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
                .lineLimit(3)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.7))
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

// MARK: - Password Reset View

struct PasswordResetView: View {
    @ObservedObject var viewModel: EmailAuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                MainAccentGradient()

                // 浮遊する円（背景装飾）
                FloatingCircles()

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
                        dismiss()
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
                HStack(spacing: 10) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                    }

                    Text(viewModel.isLoading ? "送信中..." : "リセットメールを送信")
                        .font(.headline)
                        .fontWeight(.bold)
                }
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
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                .shadow(color: Color(hex: "FF9A8B").opacity(0.3), radius: 15, x: 0, y: 8)
            }
            .disabled(viewModel.isLoading || viewModel.resetEmail.isEmpty)
            .opacity((viewModel.resetEmail.isEmpty || viewModel.isLoading) ? 0.6 : 1.0)

            // エラーメッセージ
            if let errorMessage = viewModel.errorMessage {
                ErrorMessageCard(message: errorMessage) {
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
                dismiss()
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

struct EmailAuthView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthenticationManager()
        let factory = ViewModelFactory(
            authenticationManager: authManager,
            userService: UserService.shared,
            heartbeatService: HeartbeatService.shared,
            vibrationService: VibrationService.shared
        )
        return EmailAuthView(factory: factory)
            .environmentObject(authManager)
            .environmentObject(factory)
    }
}

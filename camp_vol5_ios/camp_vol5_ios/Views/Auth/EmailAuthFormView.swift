// Views/Auth/EmailAuthFormView.swift
// メール認証フォームビュー
// サインイン・サインアップフォームとメール確認画面を含む

import SwiftUI

struct EmailAuthFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject private var authenticationManager: AuthenticationManager

    var body: some View {
        VStack(spacing: 18) {
            if viewModel.needsEmailVerification {
                EmailVerificationView(viewModel: viewModel)
            } else {
                AuthenticationFormView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Email Verification View

private struct EmailVerificationView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject private var authenticationManager: AuthenticationManager

    var body: some View {
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

                Text("登録したメールアドレスに確認メールを送信しました。\nメール内のリンクをタップしてください。")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                Text("確認後、アプリに戻ると自動的に認証が完了します。")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            // ボタン
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.sendVerificationEmail()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.callout)
                        Text("確認メールを再送信")
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
                .disabled(authenticationManager.isLoading)

                // 別のメールアドレスで登録
                Button(action: {
                    viewModel.toggleEmailVerification()
                }) {
                    Text("別のメールアドレスで登録")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .underline()
                }
                .disabled(authenticationManager.isLoading)
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Authentication Form View

private struct AuthenticationFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject private var authenticationManager: AuthenticationManager

    var body: some View {
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
                                .tint(.blue)
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
                    .background(.base)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                }
                .disabled(authenticationManager.isLoading)
                .opacity(viewModel.isFormValid ? 1.0 : 0.6)

                // サブボタン（小さめ）
                VStack(spacing: 12) {
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

                    // メール確認待ちユーザーの場合、確認画面に戻るボタンを表示
                    if viewModel.hasUnverifiedEmailUser {
                        Button(action: {
                            viewModel.toggleEmailVerification()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.badge.shield.half.filled")
                                    .font(.callout)
                                Text("メール確認画面に戻る")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.yellow.opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "FFD93D").opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                        }
                    }
                }

                // エラーメッセージ
                if let errorMessage = viewModel.errorMessage {
                    MessageBanner.error(message: errorMessage) {
                        viewModel.clearError()
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Preview

#Preview("Authentication Form") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        EmailAuthFormView(viewModel: AuthViewModel())
            .environmentObject(AuthenticationManager())
    }
}

#Preview("Email Verification") {
    let authManager = AuthenticationManager()
    authManager.needsEmailVerification = true

    return ZStack {
        LinearGradient(
            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        EmailAuthFormView(viewModel: AuthViewModel(authenticationManager: authManager))
            .environmentObject(authManager)
    }
}

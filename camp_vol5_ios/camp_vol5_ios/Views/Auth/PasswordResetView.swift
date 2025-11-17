// Views/Auth/PasswordResetView.swift
// パスワードリセットビュー
// リセットフォームと送信完了画面を含む

import SwiftUI

struct PasswordResetView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject private var authenticationManager: AuthenticationManager

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                MainAccentGradient()

                ScrollView {
                    VStack(spacing: 28) {
                        if viewModel.passwordResetSent {
                            PasswordResetSuccessView(viewModel: viewModel)
                        } else {
                            PasswordResetFormView(viewModel: viewModel)
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
}

// MARK: - Password Reset Form View

private struct PasswordResetFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject private var authenticationManager: AuthenticationManager

    var body: some View {
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
                    if viewModel.isEmailLoading {
                        ProgressView()
                            .tint(.blue)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                            .foregroundColor(.accent)
                    }

                    Text(viewModel.isEmailLoading ? "送信中..." : "リセットメールを送信")
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
            .disabled(authenticationManager.isLoading || viewModel.resetEmail.isEmpty)
            .opacity((viewModel.resetEmail.isEmpty || viewModel.isLoading) ? 0.6 : 1.0)

            // エラーメッセージ
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    viewModel.clearError()
                }
            }
        }
    }
}

// MARK: - Password Reset Success View

private struct PasswordResetSuccessView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
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
                            colors: [.green, .green.opacity(0.8)],
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
                iconColor: .green,
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

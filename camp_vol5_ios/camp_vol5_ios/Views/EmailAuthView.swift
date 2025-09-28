// Views/EmailAuthView.swift
// メール・パスワード認証用のSwiftUIビュー
// サインインとサインアップ機能を含む
// OnboardingViewとの統合対応

import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: EmailAuthViewModel
    @Environment(\.dismiss) private var dismiss

    init() {
        // 初期化時はダミーのAuthenticationManagerを使用
        // 実際のAuthenticationManagerは@EnvironmentObjectで注入される
        self._viewModel = StateObject(wrappedValue: EmailAuthViewModel(authenticationManager: AuthenticationManager()))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダーセクション
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.green.opacity(0.2), Color.green.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .scaleEffect(viewModel.animateForm ? 1.0 : 0.8)

                            Image(systemName: "envelope.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.green)
                        }

                        VStack(spacing: 8) {
                            Text(viewModel.authModeTitle)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(viewModel.authModeSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    .opacity(viewModel.animateForm ? 1.0 : 0.7)

                    // フォームセクション
                    VStack(spacing: 16) {

                        // メールアドレス入力欄
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メールアドレス")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            TextField("メールアドレスを入力", text: $viewModel.email)
                                .textFieldStyle(ModernTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }

                        // パスワード入力欄
                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            HStack {
                                Group {
                                    if viewModel.showPassword {
                                        TextField("パスワードを入力", text: $viewModel.password)
                                    } else {
                                        SecureField("パスワードを入力", text: $viewModel.password)
                                    }
                                }
                                .textContentType(viewModel.isSignUp ? .newPassword : .password)

                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.togglePasswordVisibility()
                                    }
                                }) {
                                    Image(systemName: viewModel.showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                        .font(.title3)
                                }
                            }
                            .textFieldStyle(ModernTextFieldStyle())

                            if viewModel.isSignUp {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("パスワードは6文字以上で入力してください")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .transition(.opacity)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .opacity(viewModel.animateForm ? 1.0 : 0.5)

                    // ボタンセクション
                    VStack(spacing: 16) {
                        // メイン認証ボタン
                        Button(action: {
                            viewModel.signInWithEmail()
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: viewModel.isSignUp ? "person.badge.plus" : "envelope")
                                        .font(.title3)
                                }

                                Text(viewModel.primaryButtonTitle)
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
                        .disabled(viewModel.isLoading || !viewModel.isFormValid)
                        .opacity(viewModel.isFormValid ? 1.0 : 0.6)

                        // モード切り替えボタン
                        Button(action: {
                            viewModel.toggleAuthMode()
                        }) {
                            Text(viewModel.toggleModeText)
                                .font(.callout)
                                .foregroundColor(.blue)
                                .underline()
                        }
                    }

                    // エラーメッセージ
                    if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.callout)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)

                            Button("エラーを閉じる") {
                                viewModel.clearError()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .fontWeight(.medium)
                            Text("戻る")
                                .font(.body)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onAppear {
                viewModel.updateAuthenticationManager(authenticationManager)
            }
        }
    }

}


struct EmailAuthView_Previews: PreviewProvider {
    static var previews: some View {
        EmailAuthView()
            .environmentObject(AuthenticationManager())
    }
}

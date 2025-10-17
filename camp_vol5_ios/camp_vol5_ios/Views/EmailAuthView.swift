// Views/EmailAuthView.swift
// メール・パスワード認証用のSwiftUIビュー
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
            ScrollView {
                VStack(spacing: 24) {
                    // メール確認待ち画面
                    if viewModel.needsEmailVerification {
                        emailVerificationView
                    } else {
                        // 通常の認証フォーム
                        authenticationFormView
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
                    Button(action: {
                        // メール確認待ち状態の場合、確認ダイアログを表示
                        if viewModel.needsEmailVerification {
                            showDismissConfirmation = true
                        } else {
                            dismiss()
                        }
                    }) {
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
            .alert("メール確認が完了していません", isPresented: $showDismissConfirmation) {
                Button("戻らずに確認する", role: .cancel) {}
                Button("キャンセルして戻る", role: .destructive) {
                    // アカウントを削除してから戻る
                    authenticationManager.signOut()
                    dismiss()
                }
            } message: {
                Text("メールアドレスの確認が完了していません。戻る場合、作成したアカウントからサインアウトされます。")
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
        }
        .sheet(isPresented: $viewModel.showPasswordReset) {
            PasswordResetView(viewModel: viewModel)
        }
    }

    // MARK: - Email Verification View

    private var emailVerificationView: some View {
        VStack(spacing: 24) {
            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.2), Color.blue.opacity(0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.top, 40)

            // タイトルとメッセージ
            VStack(spacing: 12) {
                Text("メールアドレスを確認してください")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("登録したメールアドレスに確認メールを送信しました。\nメール内のリンクをクリックして、メールアドレスを確認してください。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            // ボタンセクション
            VStack(spacing: 16) {
                // 確認完了ボタン
                Button(action: {
                    viewModel.checkEmailVerification()
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                        }

                        Text("確認完了")
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
                .disabled(viewModel.isLoading)

                // 確認メール再送信ボタン
                Button(action: {
                    viewModel.sendVerificationEmail()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("確認メールを再送信")
                            .font(.callout)
                    }
                    .foregroundColor(.blue)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 8)

            // 注意事項
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("メールが届かない場合")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("• 迷惑メールフォルダを確認してください")
                    Text("• メールアドレスが正しいか確認してください")
                    Text("• 確認メールの再送信をお試しください")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 8)

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
        }
    }

    // MARK: - Authentication Form View

    private var authenticationFormView: some View {
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
                            Image(
                                systemName: viewModel.showPassword
                                    ? "eye.slash.fill" : "eye.fill"
                            )
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
                            Image(
                                systemName: viewModel.isSignUp
                                    ? "person.badge.plus" : "envelope"
                            )
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

                // パスワードを忘れた場合のリンク（サインインモードのみ表示）
                if !viewModel.isSignUp {
                    Button(action: {
                        viewModel.showPasswordResetSheet()
                    }) {
                        Text("パスワードをお忘れですか？")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .underline()
                    }
                    .padding(.top, 4)
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
        }
    }

}

// MARK: - Password Reset View

struct PasswordResetView: View {
    @ObservedObject var viewModel: EmailAuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 成功メッセージまたはフォーム
                    if viewModel.passwordResetSent {
                        passwordResetSuccessView
                    } else {
                        passwordResetFormView
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("パスワードリセット")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        viewModel.dismissPasswordReset()
                        dismiss()
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
        }
    }

    // MARK: - Password Reset Form View

    private var passwordResetFormView: some View {
        VStack(spacing: 24) {
            // アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.2), Color.orange.opacity(0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "key.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.orange)
            }
            .padding(.top, 40)

            // タイトルとメッセージ
            VStack(spacing: 12) {
                Text("パスワードをリセット")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("登録したメールアドレスを入力してください。\nパスワードリセット用のリンクを送信します。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            // メールアドレス入力欄
            VStack(alignment: .leading, spacing: 8) {
                Text("メールアドレス")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                TextField("メールアドレスを入力", text: $viewModel.resetEmail)
                    .textFieldStyle(ModernTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding(.horizontal, 8)

            // 送信ボタン
            Button(action: {
                viewModel.sendPasswordResetEmail()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "envelope.fill")
                            .font(.title3)
                    }

                    Text(viewModel.isLoading ? "送信中..." : "リセットメールを送信")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(viewModel.isLoading || viewModel.resetEmail.isEmpty)
            .opacity((viewModel.resetEmail.isEmpty || viewModel.isLoading) ? 0.6 : 1.0)

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
        }
    }

    // MARK: - Password Reset Success View

    private var passwordResetSuccessView: some View {
        VStack(spacing: 24) {
            // 成功アイコン
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
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.top, 60)

            // タイトルとメッセージ
            VStack(spacing: 12) {
                Text("メールを送信しました")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("パスワードリセット用のリンクを\n\(viewModel.resetEmail)\nに送信しました。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            // 注意事項
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("メールが届かない場合")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("• 迷惑メールフォルダを確認してください")
                    Text("• メールアドレスが正しいか確認してください")
                    Text("• 数分待ってから再度お試しください")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 8)

            // 完了ボタン
            Button(action: {
                viewModel.dismissPasswordReset()
                dismiss()
            }) {
                Text("完了")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
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

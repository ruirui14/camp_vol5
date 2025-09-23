// Views/EmailAuthView.swift
// メール・パスワード認証用のSwiftUIビュー
// サインインとサインアップ機能を含む
// OnboardingViewとの統合対応

import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var isSignUp: Bool = false
    @State private var showPassword: Bool = false
    @State private var animateForm: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダーセクション
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .scaleEffect(animateForm ? 1.0 : 0.8)

                            Image(systemName: "envelope.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.green)
                        }

                        VStack(spacing: 8) {
                            Text(isSignUp ? "アカウント作成" : "サインイン")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(isSignUp ? "新しいアカウントを作成します" : "既存のアカウントでログインします")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    .opacity(animateForm ? 1.0 : 0.7)

                    // フォームセクション
                    VStack(spacing: 16) {
                        // サインアップ時のみ表示される名前入力欄
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("名前")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                TextField("名前を入力", text: $name)
                                    .textFieldStyle(ModernTextFieldStyle())
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // メールアドレス入力欄
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メールアドレス")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)

                            TextField("example@domain.com", text: $email)
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
                                    if showPassword {
                                        TextField("パスワードを入力", text: $password)
                                    } else {
                                        SecureField("パスワードを入力", text: $password)
                                    }
                                }
                                .textContentType(isSignUp ? .newPassword : .password)

                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showPassword.toggle()
                                    }
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                        .font(.title3)
                                }
                            }
                            .textFieldStyle(ModernTextFieldStyle())

                            if isSignUp {
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
                    .opacity(animateForm ? 1.0 : 0.5)

                    // ボタンセクション
                    VStack(spacing: 16) {
                        // メイン認証ボタン
                        Button(action: {
                            if isSignUp {
                                authenticationManager.signUpWithEmail(email: email, password: password, name: name)
                            } else {
                                authenticationManager.signInWithEmail(email: email, password: password)
                            }
                        }) {
                            HStack {
                                if authenticationManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: isSignUp ? "person.badge.plus" : "envelope")
                                        .font(.title3)
                                }

                                Text(authenticationManager.isLoading ? "処理中..." : (isSignUp ? "アカウント作成" : "サインイン"))
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
                        .disabled(authenticationManager.isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)

                        // モード切り替えボタン
                        Button(action: {
                            isSignUp.toggle()
                            authenticationManager.clearError()
                        }) {
                            Text(isSignUp ? "既にアカウントをお持ちの方はこちら" : "新規アカウント作成はこちら")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .underline()
                        }
                    }

                    // エラーメッセージ
                    if let errorMessage = authenticationManager.errorMessage {
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
                                authenticationManager.clearError()
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
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateForm = true
                }
            }
        }
    }

    // フォームの有効性をチェック
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !name.isEmpty && isValidEmail(email)
        } else {
            return !email.isEmpty && !password.isEmpty && isValidEmail(email)
        }
    }

    // メールアドレスの有効性をチェック
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// モダンなテキストフィールドスタイル
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
            )
            .font(.body)
    }
}

struct EmailAuthView_Previews: PreviewProvider {
    static var previews: some View {
        EmailAuthView()
            .environmentObject(AuthenticationManager())
    }
}
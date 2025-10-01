// Views/Settings/AccountDeletionView.swift
// アカウント削除画面 - アカウントの完全削除機能を提供
// SwiftUIベストプラクティスに従い、確認フローと安全性を重視

import SwiftUI

struct AccountDeletionView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showConfirmation = false
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var showFinalConfirmation = false

    private let requiredText = "削除する"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 警告セクション
                AccountDeletionWarningSection()

                // 削除される内容
                AccountDeletionContentSection()

                // 確認入力セクション
                AccountDeletionConfirmationSection(
                    confirmationText: $confirmationText,
                    requiredText: requiredText
                )

                // 削除ボタン
                AccountDeletionButton(
                    isDeleting: isDeleting,
                    isEnabled: confirmationText == requiredText && !isDeleting,
                    onTap: {
                        showFinalConfirmation = true
                    }
                )

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle("アカウント削除")
        .navigationBarTitleDisplayMode(.inline)
        .alert("最終確認", isPresented: $showFinalConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除する", role: .destructive) {
                performAccountDeletion()
            }
        } message: {
            Text("本当にアカウントを削除しますか？この操作は取り消すことができません。")
        }
        .alert(
            "エラー", isPresented: .constant(authenticationManager.errorMessage != nil && isDeleting)
        ) {
            Button("OK") {
                authenticationManager.clearError()
                isDeleting = false
            }
        } message: {
            if let errorMessage = authenticationManager.errorMessage {
                Text(errorMessage)
            }
        }
        .onChange(of: authenticationManager.isAuthenticated) { isAuthenticated in
            // アカウント削除が成功した場合（認証状態がfalseになった場合）
            // ContentViewが自動的にログイン画面に切り替えるため、何もする必要なし
            if !isAuthenticated && isDeleting {
                // AuthenticationManagerの状態変更により、ContentViewが自動的にAuthViewに切り替わる
                isDeleting = false
            }
        }
    }

    private func performAccountDeletion() {
        isDeleting = true
        authenticationManager.deleteAccount()
    }
}

struct AccountDeletionWarningSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 4) {
                    Text("重要な注意事項")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)

                    Text("この操作は取り消すことができません")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct AccountDeletionContentSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("削除される内容")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                DeletionItem(
                    icon: "person.circle",
                    title: "アカウント情報",
                    description: "ユーザー名、招待コードなどのプロフィール情報"
                )

                DeletionItem(
                    icon: "heart.circle",
                    title: "心拍データ",
                    description: "これまでに送信された心拍情報"
                )

                DeletionItem(
                    icon: "person.2.circle",
                    title: "フォロー関係",
                    description: "他のユーザーとのつながり情報"
                )

                DeletionItem(
                    icon: "photo.circle",
                    title: "カスタム背景画像",
                    description: "設定した背景画像とその編集情報"
                )
            }
        }
    }
}

struct AccountDeletionConfirmationSection: View {
    @Binding var confirmationText: String
    let requiredText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("削除を確認")
                .font(.headline)
                .fontWeight(.semibold)

            Text("アカウント削除を実行するには、下記のテキストフィールドに「\(requiredText)」と入力してください。")
                .font(.body)
                .foregroundColor(.secondary)

            TextField("ここに入力", text: $confirmationText)
                .textFieldStyle(ModernTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
}

struct AccountDeletionButton: View {
    let isDeleting: Bool
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                if isDeleting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                }

                Text(isDeleting ? "削除中..." : "アカウントを削除")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct DeletionItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.red)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        AccountDeletionView(
            viewModel: SettingsViewModel(authenticationManager: AuthenticationManager())
        )
        .environmentObject(AuthenticationManager())
    }
}

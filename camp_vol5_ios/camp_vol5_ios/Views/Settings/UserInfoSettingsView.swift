// Views/Settings/UserInfoSettingsView.swift
// ユーザー情報設定画面 - 現在のユーザー情報と認証状態を表示
// SwiftUIベストPラクティスに従い、読み取り専用の情報表示として実装

import SwiftUI

struct UserInfoSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("ユーザー情報") {
                UserInfoContent(viewModel: viewModel)
            }
        }
        .navigationTitle("ユーザー情報")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UserInfoContent: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var authenticationManager: AuthenticationManager

    var body: some View {
        VStack(spacing: 16) {
            // 認証状態セクション
            AuthenticationStatusSection(authenticationManager: authenticationManager)

            // エラーメッセージ表示
            if let errorMessage = authenticationManager.errorMessage {
                ErrorMessageView(errorMessage: errorMessage) {
                    authenticationManager.clearError()
                }
            }

            // ユーザー情報セクション
            UserDetailSection(user: viewModel.currentUser)
        }
    }
}

struct AuthenticationStatusSection: View {
    let authenticationManager: AuthenticationManager

    var body: some View {
        HStack {
            Image(
                systemName: authenticationManager.isAuthenticated
                    ? "checkmark.circle.fill" : "person.circle"
            )
            .foregroundColor(
                authenticationManager.isAuthenticated ? .green : .orange
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    authenticationManager.isAuthenticated
                        ? "認証済み" : "未認証"
                )
                .font(.headline)

                if let firebaseUser = authenticationManager.user,
                    let email = firebaseUser.email
                {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("認証済みでフル機能が利用できます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}

struct ErrorMessageView: View {
    let errorMessage: String
    let onTap: () -> Void

    var body: some View {
        Text(errorMessage)
            .foregroundColor(.red)
            .font(.caption)
            .onTapGesture {
                onTap()
            }
    }
}

struct UserDetailSection: View {
    let user: User?

    var body: some View {
        if let user = user {
            VStack(spacing: 12) {
                UserInfoRow(label: "名前", value: user.name)
                UserInfoRow(label: "招待コード", value: user.inviteCode, isMonospaced: true)
            }
        } else {
            LoadingUserInfoView()
        }
    }
}

struct UserInfoRow: View {
    let label: String
    let value: String
    let isMonospaced: Bool

    init(label: String, value: String, isMonospaced: Bool = false) {
        self.label = label
        self.value = value
        self.isMonospaced = isMonospaced
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(isMonospaced ? .system(.caption, design: .monospaced) : .body)
        }
    }
}

struct LoadingUserInfoView: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("ユーザー情報を読み込み中...")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        UserInfoSettingsView(
            viewModel: SettingsViewModel(authenticationManager: AuthenticationManager())
        )
        .environmentObject(AuthenticationManager())
    }
}

// Views/Components/SettingsNavigationSection.swift
// 設定画面のナビゲーションセクションコンポーネント - 各設定項目への導線を提供
// SwiftUIベストプラクティスに従い、ナビゲーション要素を集約

import SwiftUI

struct SettingsNavigationSection: View {
    @ObservedObject var viewModel: SettingsViewModel
    let autoLockManager: AutoLockManager
    @ObservedObject private var themeManager = ColorThemeManager.shared
    @Environment(\.openURL) private var openURL
    @State private var showEmailConfirmation = false
    @State private var showSecondConfirmation = false
    @State private var navigateToUserInfo = false
    @State private var showColorResetAlert = false

    var body: some View {
        Section {
            Button {
                showEmailConfirmation = true
            } label: {
                HStack {
                    SettingRow(
                        icon: "person.circle",
                        title: "ユーザー情報",
                        subtitle: "名前、招待コードの管理"
                    )
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .navigationDestination(isPresented: $navigateToUserInfo) {
                UserInfoSettingsView(viewModel: viewModel)
            }
            .alert("確認", isPresented: $showEmailConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("はい") {
                    showSecondConfirmation = true
                }
            } message: {
                Text("⚠️ 個人情報（メールアドレスなど）\nが表示されますが、よろしいですか?")
            }
            .alert("最終確認", isPresented: $showSecondConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("はい") {
                    navigateToUserInfo = true
                }
            } message: {
                Text("本当によろしいですか？")
            }

            NavigationLink(destination: UserNameEditView(viewModel: viewModel)) {
                SettingRow(
                    icon: "pencil.circle",
                    title: "ユーザー名変更",
                    subtitle: "表示名を変更します"
                )
            }

            NavigationLink(destination: HeartbeatSettingsView(viewModel: viewModel)) {
                SettingRow(
                    icon: "heart.circle",
                    title: "自分のデータ",
                    subtitle: "現在の心拍情報・同時接続者数を確認"
                )
            }

            NavigationLink(destination: AutoLockSettingsView(autoLockManager: autoLockManager)) {
                SettingRow(
                    icon: "lock.circle",
                    title: "自動ロック無効化",
                    subtitle: "画面オフ設定の管理"
                )
            }

            NavigationLink(destination: AutoSleepSettingsView()) {
                SettingRow(
                    icon: "moon.circle",
                    title: "画面自動OFF",
                    subtitle: "下向き検知で自動スリープ"
                )
            }

            Button {
                showColorResetAlert = true
            } label: {
                HStack {
                    SettingRow(
                        icon: "paintpalette",
                        title: "カラーテーマをリセット",
                        subtitle: "デフォルトの色に戻します"
                    )
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .alert("カラーテーマをリセット", isPresented: $showColorResetAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("リセット", role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        themeManager.resetToDefaults()
                    }
                }
            } message: {
                Text("カラーテーマをデフォルトに戻しますか？")
            }

            NavigationLink(destination: TermsOfServiceView()) {
                SettingRow(
                    icon: "doc.text",
                    title: "利用規約",
                    subtitle: "アプリの利用規約を確認"
                )
            }

            NavigationLink(destination: PrivacyPolicyView()) {
                SettingRow(
                    icon: "lock.doc",
                    title: "プライバシーポリシー",
                    subtitle: "個人情報の取り扱いについて"
                )
            }

            NavigationLink(destination: LicensesView()) {
                SettingRow(
                    icon: "doc.plaintext",
                    title: "Licenses",
                    subtitle: "使用しているライブラリのライセンス"
                )
            }

            Button {
                if let url = URL(
                    string:
                        "https://docs.google.com/forms/d/e/1FAIpQLSewUP_6Bftp45lILNpjKl31O8rHkescQAwVOP5IyNjVJEckgQ/viewform"
                ) {
                    openURL(url)
                }
            } label: {
                HStack {
                    SettingRow(
                        icon: "envelope.circle",
                        title: "お問い合わせ",
                        subtitle: "フィードバックやご質問はこちら"
                    )
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            NavigationLink(destination: AccountDeletionView(viewModel: viewModel)) {
                SettingRow(
                    icon: "trash.circle",
                    title: "アカウント削除",
                    subtitle: "アカウントとデータを完全に削除"
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            SettingsNavigationSection(
                viewModel: SettingsViewModel(authenticationManager: AuthenticationManager()),
                autoLockManager: AutoLockManager.shared
            )
        }
    }
}

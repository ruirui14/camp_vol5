// Views/Components/SettingsNavigationSection.swift
// 設定画面のナビゲーションセクションコンポーネント - 各設定項目への導線を提供
// SwiftUIベストプラクティスに従い、ナビゲーション要素を集約

import SwiftUI

struct SettingsNavigationSection: View {
    let viewModel: SettingsViewModel
    let autoLockManager: AutoLockManager

    var body: some View {
        Section {
            NavigationLink(destination: UserInfoSettingsView(viewModel: viewModel)) {
                SettingRow(
                    icon: "person.circle",
                    title: "ユーザー情報",
                    subtitle: "名前、招待コードの管理"
                )
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
                    title: "自分の心拍データ",
                    subtitle: "現在の心拍情報を確認"
                )
            }

            NavigationLink(destination: AutoLockSettingsView(autoLockManager: autoLockManager)) {
                SettingRow(
                    icon: "lock.circle",
                    title: "自動ロック無効化",
                    subtitle: "画面オフ設定の管理"
                )
            }

            NavigationLink(destination: TermsOfServiceView()) {
                SettingRow(
                    icon: "doc.text.circle",
                    title: "利用規約",
                    subtitle: "アプリの利用規約を確認"
                )
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
    NavigationView {
        Form {
            SettingsNavigationSection(
                viewModel: SettingsViewModel(authenticationManager: AuthenticationManager()),
                autoLockManager: AutoLockManager.shared
            )
        }
    }
}
// Views/Components/SettingsSignOutSection.swift
// 設定画面のサインアウトセクションコンポーネント - サインアウト機能を提供
// SwiftUIベストプラクティスに従い、アクションを外部に委譲

import SwiftUI

struct SettingsSignOutSection: View {
    let onSignOut: () -> Void

    var body: some View {
        Section {
            Button("サインアウト") {
                onSignOut()
            }
            .foregroundColor(.red)
        } footer: {
            Text("サインアウトすると、ログイン画面に戻ります。")
        }
    }
}

#Preview {
    Form {
        SettingsSignOutSection(
            onSignOut: {}
        )
    }
}
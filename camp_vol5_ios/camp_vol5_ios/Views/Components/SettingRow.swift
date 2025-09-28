// Views/Components/SettingRow.swift
// 設定項目の行コンポーネント - 統一されたレイアウトとスタイリングを提供
// SwiftUIベストプラクティスに従い、再利用可能な設定行として実装

import SwiftUI

struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        SettingRow(
            icon: "person.circle",
            title: "ユーザー情報",
            subtitle: "名前、招待コードの管理"
        )

        SettingRow(
            icon: "heart.circle",
            title: "心拍データ",
            subtitle: "現在の心拍情報を確認"
        )

        SettingRow(
            icon: "lock.circle",
            title: "自動ロック無効化",
            subtitle: "画面オフ設定の管理"
        )
    }
}
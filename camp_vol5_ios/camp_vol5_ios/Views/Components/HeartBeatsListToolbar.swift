// Views/Components/HeartBeatsListToolbar.swift
// 心拍一覧画面のツールバーコンポーネント - ナビゲーションとソート機能を担当
// SwiftUIベストプラクティスに従い、アクションを外部に委譲
// ColorThemeManagerと連携して、ユーザーが選択したテーマカラーを反映

import SwiftUI

struct HeartBeatsListToolbar: ToolbarContent {
    let currentSortOption: SortOption
    let themeColor: Color
    let onNavigateToSettings: () -> Void
    let onNavigateToQRScanner: () -> Void
    let onSortOptionChanged: (SortOption) -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                onNavigateToSettings()
            } label: {
                Image(systemName: "gearshape")
                    .foregroundColor(themeColor)
            }
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            // ソートメニュー
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        onSortOptionChanged(option)
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if currentSortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(themeColor)
            }

            // QRスキャナーボタン
            Button {
                onNavigateToQRScanner()
            } label: {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(themeColor)
            }
        }
    }
}

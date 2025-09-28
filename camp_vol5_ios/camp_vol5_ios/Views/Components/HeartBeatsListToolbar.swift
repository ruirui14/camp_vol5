// Views/Components/HeartBeatsListToolbar.swift
// 心拍一覧画面のツールバーコンポーネント - ナビゲーションとソート機能を担当
// SwiftUIベストプラクティスに従い、アクションを外部に委譲

import SwiftUI

struct HeartBeatsListToolbar: ToolbarContent {
    let currentSortOption: SortOption
    let onNavigateToSettings: () -> Void
    let onNavigateToQRScanner: () -> Void
    let onSortOptionChanged: (SortOption) -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                onNavigateToSettings()
            } label: {
                Image(systemName: "gearshape")
                    .foregroundColor(.main)
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
                    .foregroundColor(.main)
            }

            // QRスキャナーボタン
            Button {
                onNavigateToQRScanner()
            } label: {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(.main)
            }
        }
    }
}
// Views/Components/SettingsToolbar.swift
// 設定画面のツールバーコンポーネント - ナビゲーションバーのカスタマイズを提供
// SwiftUIベストプラクティスに従い、プレゼンテーション制御を外部に委譲

import SwiftUI

struct SettingsToolbar: ToolbarContent {
    let onDismiss: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("戻る") {
                onDismiss()
            }
            .foregroundColor(.white)
        }

        ToolbarItem(placement: .principal) {
            Text("設定")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationStack {
        Text("Settings Content")
            .toolbar {
                SettingsToolbar(onDismiss: {})
            }
    }
}

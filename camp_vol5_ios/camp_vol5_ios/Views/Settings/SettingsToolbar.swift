// Views/Components/SettingsToolbar.swift
// 設定画面のツールバーコンポーネント - ナビゲーションバーのカスタマイズを提供
// SwiftUIベストプラクティスに従い、プレゼンテーション制御を外部に委譲

import SwiftUI

struct SettingsToolbar: ToolbarContent {
    let onDismiss: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: onDismiss) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("戻る")
                }
            }
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
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

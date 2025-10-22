// Views/Components/HeartbeatDetailToolbar.swift
// 心拍詳細画面のツールバーコンポーネント - ナビゲーションアクションを担当
// SwiftUIベストプラクティスに従い、アクションを外部に委譲

import SwiftUI

struct HeartbeatDetailToolbar: ToolbarContent {
    let userName: String
    let isVibrationEnabled: Bool
    let onDismiss: () -> Void
    let onToggleSleep: () -> Void
    let onToggleVibration: () -> Void
    let onOpenStream: () -> Void
    let onEditCardBackground: () -> Void
    let onEditBackgroundImage: () -> Void
    let onResetBackgroundImage: () -> Void
    let hasBackgroundImage: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("戻る", action: onDismiss)
                .foregroundColor(.white)
        }

        ToolbarItem(placement: .principal) {
            WhiteCapsuleTitle(title: userName.isEmpty ? "読み込み中..." : userName)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 15) {
                // 配信視聴ボタン
                Button(action: onOpenStream) {
                    Image(systemName: "play.tv")
                        .foregroundColor(.white)
                        .font(.title3)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }

                // 手動スリープボタン
                Button(action: onToggleSleep) {
                    Image(systemName: "moon.circle")
                        .foregroundColor(.white)
                        .font(.title3)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }

                // 振動制御ボタン
                Button(action: onToggleVibration) {
                    Image(
                        systemName: isVibrationEnabled
                            ? "heart.circle.fill" : "heart.circle"
                    )
                    .foregroundColor(isVibrationEnabled ? .red : .white)
                    .font(.title2)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }

                // 編集メニュー
                Menu {
                    Button("カード背景を編集", action: onEditCardBackground)
                    Button("背景画像を編集", action: onEditBackgroundImage)

                    if hasBackgroundImage {
                        Button("背景画像をリセット", role: .destructive, action: onResetBackgroundImage)
                    }
                } label: {
                    Image(systemName: "photo")
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
            }
        }
    }
}

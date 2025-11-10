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
            WhiteCapsuleTitle(title: userName.isEmpty ? "読み込み中..." : userName)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 15) {
                // 手動スリープボタン（個別）
                Button(action: onToggleSleep) {
                    Image(systemName: "moon.circle")
                        .foregroundColor(.white)
                        .font(.title3)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }

                // 統合メニュー（配信視聴、振動制御、編集機能）
                Menu {
                    // 配信視聴
                    Button(action: onOpenStream) {
                        Label("配信を視聴", systemImage: "play.tv")
                    }

                    // 振動制御
                    Button(action: onToggleVibration) {
                        Label(
                            isVibrationEnabled ? "振動をOFF" : "振動をON",
                            systemImage: isVibrationEnabled ? "heart.circle.fill" : "heart.circle"
                        )
                    }

                    Divider()

                    // 編集機能
                    Button(action: onEditCardBackground) {
                        Label("カード背景を編集", systemImage: "rectangle.fill")
                    }

                    Button(action: onEditBackgroundImage) {
                        Label("背景画像を編集", systemImage: "photo")
                    }

                    if hasBackgroundImage {
                        Button(role: .destructive, action: onResetBackgroundImage) {
                            Label("背景画像をリセット", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.white)
                        .font(.title3)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
            }
        }
    }
}

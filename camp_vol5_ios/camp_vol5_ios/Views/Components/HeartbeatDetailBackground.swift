// Views/Components/HeartbeatDetailBackground.swift
// 心拍詳細画面の背景コンポーネント - 背景色と背景画像の表示を担当
// SwiftUIベストプラクティスに従い、再利用可能なコンポーネントとして設計

import SwiftUI

struct HeartbeatDetailBackground: View {
    let backgroundImage: UIImage?
    let backgroundColor: Color
    let imageOffset: CGSize
    let imageScale: CGFloat
    let imageRotation: Double

    var body: some View {
        ZStack {
            // 背景色またはデフォルト背景
            if backgroundColor != .clear {
                backgroundColor
                    .ignoresSafeArea()
            } else {
                MainAccentGradient()
            }

            // 背景画像（ある場合のみオーバーレイ）
            if let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(imageScale)
                    .rotationEffect(.degrees(imageRotation))
                    .offset(imageOffset)
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    HeartbeatDetailBackground(
        backgroundImage: nil,
        backgroundColor: .clear,
        imageOffset: .zero,
        imageScale: 1.0,
        imageRotation: 0.0
    )
}
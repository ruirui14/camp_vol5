// Views/Components/HeartbeatDetailBackground.swift
// 心拍詳細画面の背景コンポーネント - 背景色と背景画像（GIF対応）の表示を担当
// SwiftUIベストプラクティスに従い、再利用可能なコンポーネントとして設計

import SwiftUI

struct HeartbeatDetailBackground: View {
    let backgroundImage: UIImage?
    let backgroundImageData: Data?
    let backgroundColor: Color
    let imageOffset: CGSize
    let imageScale: CGFloat
    let imageRotation: Double
    let isAnimated: Bool

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
            // GIFアニメーションの場合はAnimatedImageViewを使用
            if let imageData = backgroundImageData, isAnimated {
                AnimatedImageView(imageData: imageData, contentMode: .scaleAspectFit)
                    .scaleEffect(imageScale)
                    .rotationEffect(.degrees(imageRotation))
                    .offset(imageOffset)
                    .ignoresSafeArea()
            } else if let image = backgroundImage {
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
        backgroundImageData: nil,
        backgroundColor: .clear,
        imageOffset: .zero,
        imageScale: 1.0,
        imageRotation: 0.0,
        isAnimated: false
    )
}

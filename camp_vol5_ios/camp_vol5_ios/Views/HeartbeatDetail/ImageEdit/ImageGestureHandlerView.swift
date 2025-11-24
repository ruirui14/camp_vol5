// Views/HeartbeatDetail/ImageEdit/ImageGestureHandlerView.swift
// 画像編集画面のジェスチャー処理コンポーネント
// ドラッグ、スケール、回転のジェスチャーを管理

import SDWebImageSwiftUI
import SwiftUI

/// 画像のドラッグ、スケール、回転を管理するビュー
struct ImageGestureHandlerView: View {
    // MARK: - Properties

    let image: UIImage?
    let imageData: Data?
    let isAnimatedImage: Bool
    @Binding var tempOffset: CGSize
    @Binding var lastOffset: CGSize
    @Binding var tempScale: CGFloat
    @Binding var lastScale: CGFloat
    @Binding var tempRotation: Double
    @Binding var lastRotation: Double

    // MARK: - Body

    var body: some View {
        Group {
            if let data = imageData, isAnimatedImage {
                // GIFアニメーションの場合
                animatedImageView(data: data)
            } else if let image = image {
                // 通常の画像の場合
                staticImageView(image: image)
            } else {
                // 画像が選択されていない場合のプレースホルダー
                placeholderView
            }
        }
    }

    // MARK: - Subviews

    /// GIFアニメーション用のビュー
    private func animatedImageView(data: Data) -> some View {
        ZStack {
            AnimatedImage(data: data)
                .resizable()
                .scaledToFit()
                .scaleEffect(tempScale)
                .rotationEffect(.degrees(tempRotation))
                .offset(tempOffset)
                .ignoresSafeArea()

            // ジェスチャー用の透明レイヤー
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .gesture(combinedGesture)
        }
    }

    /// 通常の画像用のビュー
    private func staticImageView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(tempScale)
            .rotationEffect(.degrees(tempRotation))
            .offset(tempOffset)
            .ignoresSafeArea()
            .gesture(combinedGesture)
    }

    /// 画像未選択時のプレースホルダー
    private var placeholderView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))

            Text("写真を選択してください")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Gestures

    /// 複合ジェスチャー（ドラッグ、スケール、回転）
    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            SimultaneousGesture(
                dragGesture,
                magnificationGesture
            ),
            rotationGesture
        )
    }

    /// ドラッグジェスチャー
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                tempOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = tempOffset
            }
    }

    /// 拡大縮小ジェスチャー
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                tempScale = lastScale * value
            }
            .onEnded { _ in
                lastScale = tempScale
                // スケールの範囲を制限
                if tempScale < 0.5 {
                    tempScale = 0.5
                    lastScale = 0.5
                } else if tempScale > 5.0 {
                    tempScale = 5.0
                    lastScale = 5.0
                }
            }
    }

    /// 回転ジェスチャー
    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                tempRotation = lastRotation + value.degrees
            }
            .onEnded { _ in
                lastRotation = tempRotation
            }
    }
}

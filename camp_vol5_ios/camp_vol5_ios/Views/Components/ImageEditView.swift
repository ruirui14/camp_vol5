// Views/Components/ImageEditView.swift
// 拡張画像編集ビュー

import SwiftUI

// MARK: - 拡張画像編集ビュー
struct ImageEditView: View {
    @State private var transform: ImageTransform
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGPoint = .zero

    let image: UIImage
    let onComplete: (ImageTransform) -> Void
    let onCancel: () -> Void

    init(
        image: UIImage,
        initialTransform: ImageTransform = ImageTransform(),
        onComplete: @escaping (ImageTransform) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.image = image
        self._transform = State(initialValue: initialTransform)
        self._lastScale = State(initialValue: initialTransform.scale)
        self._lastOffset = State(initialValue: initialTransform.normalizedOffset)
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(transform.scale)
                        .offset(
                            x: transform.normalizedOffset.x * geometry.size.width / 2,
                            y: transform.normalizedOffset.y * geometry.size.height / 2
                        )
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        transform.scale = lastScale * value
                                    }
                                    .onEnded { value in
                                        lastScale = transform.scale
                                        if transform.scale < 0.5 {
                                            transform.scale = 0.5
                                            lastScale = 0.5
                                        } else if transform.scale > 3.0 {
                                            transform.scale = 3.0
                                            lastScale = 3.0
                                        }
                                    },

                                DragGesture()
                                    .onChanged { value in
                                        let newOffsetX =
                                            lastOffset.x
                                            + (value.translation.width / geometry.size.width * 2)
                                        let newOffsetY =
                                            lastOffset.y
                                            + (value.translation.height / geometry.size.height * 2)

                                        transform.normalizedOffset = CGPoint(
                                            x: max(-1.0, min(1.0, newOffsetX)),
                                            y: max(-1.0, min(1.0, newOffsetY))
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = transform.normalizedOffset
                                    }
                            )
                        )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("画像を編集")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("決定") {
                        onComplete(transform)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - シンプル背景画像表示ビュー
struct SimpleBackgroundImageView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
    }
}

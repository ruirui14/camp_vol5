import SwiftUI

/// カード背景画像を変形可能にするビュー
/// ピンチ、回転、ドラッグのマルチタッチジェスチャーに対応
struct TransformableCardImageView: View {
    /// 表示する画像
    let image: UIImage

    /// カードのサイズ（幅と高さ）
    let cardSize: CGSize

    /// 変形状態を管理するオブジェクト
    @ObservedObject var transformState: CardImageTransformState

    /// ジェスチャー中の一時的な拡大率
    @GestureState private var gestureScale: CGFloat = 1.0

    /// ジェスチャー中の一時的な回転角度
    @GestureState private var gestureAngle: Angle = .zero

    /// ジェスチャー中の一時的なオフセット
    @GestureState private var gestureOffset: CGSize = .zero

    /// 最小拡大率
    private let minScale: CGFloat = 0.1

    /// 最大拡大率
    private let maxScale: CGFloat = 5.0

    /// カードの角丸半径（CardConstantsから取得）
    private let cornerRadius: CGFloat = CardConstants.cornerRadius

    var body: some View {
        // ピンチジェスチャー（拡大縮小）
        let magnificationGesture = MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let newScale = transformState.currentScale * value
                transformState.currentScale = min(max(newScale, minScale), maxScale)
            }

        // 回転ジェスチャー
        let rotationGesture = RotationGesture()
            .updating($gestureAngle) { value, state, _ in
                state = value
            }
            .onEnded { value in
                transformState.currentAngle += value
            }

        // ドラッグジェスチャー（移動）
        let dragGesture = DragGesture()
            .updating($gestureOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                transformState.currentOffset.width += value.translation.width
                transformState.currentOffset.height += value.translation.height
            }

        // 3つのジェスチャーを同時に認識
        let combinedGesture =
            magnificationGesture
            .simultaneously(with: rotationGesture)
            .simultaneously(with: dragGesture)

        ZStack {
            // 背景（編集中であることを示すグリッド）
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.1))
                .frame(width: cardSize.width, height: cardSize.height)

            // カード範囲外の画像（半透明で表示）
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: cardSize.width * 2, height: cardSize.height * 2)
                .scaleEffect(transformState.currentScale * gestureScale)
                .rotationEffect(transformState.currentAngle + gestureAngle)
                .offset(
                    x: transformState.currentOffset.width + gestureOffset.width,
                    y: transformState.currentOffset.height + gestureOffset.height
                )
                .frame(width: cardSize.width, height: cardSize.height)
                .opacity(0.3)  // カード範囲外を半透明で表示

            // カード範囲内の画像（通常表示）
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: cardSize.width * 2, height: cardSize.height * 2)
                .scaleEffect(transformState.currentScale * gestureScale)
                .rotationEffect(transformState.currentAngle + gestureAngle)
                .offset(
                    x: transformState.currentOffset.width + gestureOffset.width,
                    y: transformState.currentOffset.height + gestureOffset.height
                )
                .frame(width: cardSize.width, height: cardSize.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))  // カード形状に切り抜き
                .gesture(combinedGesture)

            // カード形状の境界線
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: cardSize.width, height: cardSize.height)
                .shadow(color: .black.opacity(0.3), radius: 5)
        }
    }

    /// 現在の変形状態で画像をキャプチャ
    /// - Parameter backgroundColor: 背景色（デフォルトは白）
    /// - Returns: レンダリングされた画像（失敗時はnil）
    func captureImage(backgroundColor: Color = .white) -> UIImage? {
        let renderer = ImageRenderer(
            content:
                ZStack {
                    backgroundColor
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardSize.width * 2, height: cardSize.height * 2)
                        .scaleEffect(transformState.currentScale)
                        .rotationEffect(transformState.currentAngle)
                        .offset(
                            x: transformState.currentOffset.width,
                            y: transformState.currentOffset.height
                        )
                        .frame(width: cardSize.width, height: cardSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
                .frame(width: cardSize.width, height: cardSize.height)
        )

        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

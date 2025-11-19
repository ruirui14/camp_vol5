import SDWebImageSwiftUI
import SwiftUI

/// カード背景画像を変形可能にするビュー（GIF対応）
/// ピンチ、回転、ドラッグのマルチタッチジェスチャーに対応
struct TransformableCardImageView: View {
    /// 表示する画像
    let image: UIImage

    /// 画像データ（GIF対応）
    let imageData: Data?

    /// アニメーション画像かどうか
    let isAnimated: Bool

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

    init(
        image: UIImage,
        imageData: Data? = nil,
        isAnimated: Bool = false,
        cardSize: CGSize,
        transformState: CardImageTransformState
    ) {
        self.image = image
        self.imageData = imageData
        self.isAnimated = isAnimated
        self.cardSize = cardSize
        self.transformState = transformState
    }

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

        // GIFの場合と通常の画像で異なる処理
        // ImageEditViewの実装を参考に、GIFの場合のみ透明レイヤーを使用
        if isAnimated {
            // GIFの場合：透明レイヤーを最上層に追加してジェスチャーを受け取る
            ZStack {
                mainContent

                // 透明なジェスチャー受付レイヤー（GIF専用）
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(combinedGesture)
            }
        } else {
            // 通常の画像の場合：ZStack全体にジェスチャーを適用（元の実装）
            mainContent
                .gesture(combinedGesture)
        }
    }

    /// メインコンテンツ（画像表示部分）
    private var mainContent: some View {
        ZStack {
            // 背景（編集中であることを示すグリッド）
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.1))
                .frame(width: cardSize.width, height: cardSize.height)

            // カード範囲外の画像（半透明で表示）
            transformedImageView
                .frame(width: cardSize.width, height: cardSize.height)
                .opacity(0.3)

            // カード範囲内の画像（通常表示、カード形状に切り抜き）
            transformedImageView
                .frame(width: cardSize.width, height: cardSize.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // カード形状の境界線
            cardBorderView
        }
    }

    /// 変形が適用された画像ビュー（GIF対応）
    private var transformedImageView: some View {
        createImageView()
            .frame(width: cardSize.width * 2, height: cardSize.height * 2)
            .scaleEffect(transformState.currentScale * gestureScale)
            .rotationEffect(transformState.currentAngle + gestureAngle)
            .offset(
                x: transformState.currentOffset.width + gestureOffset.width,
                y: transformState.currentOffset.height + gestureOffset.height
            )
    }

    /// 画像ビューを作成（GIF対応）
    @ViewBuilder
    private func createImageView() -> some View {
        if let data = imageData, isAnimated {
            AnimatedImage(data: data)
                .resizable()
                .scaledToFit()
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        }
    }

    /// カード形状の境界線
    private var cardBorderView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(Color.white, lineWidth: 3)
            .frame(width: cardSize.width, height: cardSize.height)
            .shadow(color: .black.opacity(0.3), radius: 5)
    }

    /// 現在の変形状態で画像をキャプチャ
    /// - Parameters:
    ///   - backgroundColor: 背景色（デフォルトは白）
    ///   - sourceImage: キャプチャする画像（nilの場合は初期化時の画像を使用）
    /// - Returns: レンダリングされた画像（失敗時はnil）
    func captureImage(backgroundColor: Color = .white, sourceImage: UIImage? = nil) -> UIImage? {
        let imageToCapture = sourceImage ?? image

        let renderer = ImageRenderer(
            content:
                ZStack {
                    backgroundColor
                    Image(uiImage: imageToCapture)
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

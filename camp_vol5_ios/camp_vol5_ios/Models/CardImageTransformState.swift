import SwiftUI

/// カード画像の変形状態を管理するObservableObject
/// 拡大率、回転角度、移動量を保持し、リアルタイムで変更を通知
class CardImageTransformState: ObservableObject {
    /// 現在の拡大率（デフォルト: 1.0）
    @Published var currentScale: CGFloat = 1.0

    /// 現在の回転角度（デフォルト: 0度）
    @Published var currentAngle: Angle = .zero

    /// 現在のオフセット位置（デフォルト: 中央）
    @Published var currentOffset: CGSize = .zero

    /// すべての変形状態を初期値にリセット
    func reset() {
        currentScale = 1.0
        currentAngle = .zero
        currentOffset = .zero
    }
}

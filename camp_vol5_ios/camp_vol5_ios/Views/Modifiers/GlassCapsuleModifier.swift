// Views/Modifiers/GlassCapsuleModifier.swift
// グラスモルフィズム効果のカプセル型背景スタイルを提供するカスタムViewModifier
// 複数箇所で使用される重複コードを統一し、一貫性のあるデザインを実現
// 用途: ステータスバー、タグ、ボタンなどの小さなUIコンポーネント

import SwiftUI

/// グラスモルフィズム効果を適用するカプセル型背景モディファイア
struct GlassCapsuleModifier: ViewModifier {
    /// グラデーションに使用する色配列
    let gradientColors: [Color]
    /// 背景の不透明度（デフォルト: 0.12）
    let fillOpacity: Double
    /// シャドウの不透明度（デフォルト: 0.15）
    let shadowOpacity: Double
    /// ストローク線の太さ（デフォルト: 0.5）
    let strokeLineWidth: CGFloat

    init(
        gradientColors: [Color],
        fillOpacity: Double = 0.12,
        shadowOpacity: Double = 0.15,
        strokeLineWidth: CGFloat = 0.5
    ) {
        self.gradientColors = gradientColors
        self.fillOpacity = fillOpacity
        self.shadowOpacity = shadowOpacity
        self.strokeLineWidth = strokeLineWidth
    }

    func body(content: Content) -> some View {
        content
            .background(
                Capsule()
                    .fill(Color.white.opacity(fillOpacity))
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: strokeLineWidth
                            )
                    )
            )
            .shadow(color: Color.black.opacity(shadowOpacity), radius: 6, x: 0, y: 3)
    }
}

extension View {
    /// グラスモルフィズム効果のカプセル型背景を適用
    /// - Parameters:
    ///   - gradientColors: グラデーションストロークに使用する色配列
    ///   - fillOpacity: 背景の不透明度（デフォルト: 0.12）
    ///   - shadowOpacity: シャドウの不透明度（デフォルト: 0.15）
    ///   - strokeLineWidth: ストローク線の太さ（デフォルト: 0.5）
    /// - Returns: グラスモルフィズム背景が適用されたView
    func glassCapsuleStyle(
        gradientColors: [Color],
        fillOpacity: Double = 0.12,
        shadowOpacity: Double = 0.15,
        strokeLineWidth: CGFloat = 0.5
    ) -> some View {
        modifier(
            GlassCapsuleModifier(
                gradientColors: gradientColors,
                fillOpacity: fillOpacity,
                shadowOpacity: shadowOpacity,
                strokeLineWidth: strokeLineWidth
            )
        )
    }

    /// 振動ステータス用のグラスカプセルスタイル（高い不透明度）
    func vibrationStatusGlassCapsule() -> some View {
        glassCapsuleStyle(
            gradientColors: [
                Color.white.opacity(0.3),
                Color.white.opacity(0.1),
            ],
            fillOpacity: 0.15,
            shadowOpacity: 0.2,
            strokeLineWidth: 1
        )
    }

    /// 一般ステータス用のグラスカプセルスタイル（標準不透明度）
    func statusGlassCapsule() -> some View {
        glassCapsuleStyle(
            gradientColors: [
                Color.white.opacity(0.25),
                Color.white.opacity(0.1),
            ],
            fillOpacity: 0.12,
            shadowOpacity: 0.15,
            strokeLineWidth: 0.5
        )
    }

    /// シンプルなグラスカプセルスタイル（低い不透明度）
    func simpleGlassCapsule() -> some View {
        glassCapsuleStyle(
            gradientColors: [Color.white.opacity(0.15)],
            fillOpacity: 0.1,
            shadowOpacity: 0.15,
            strokeLineWidth: 0.5
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // 振動ステータス用
        Text("振動中")
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .vibrationStatusGlassCapsule()

        // 一般ステータス用
        Text("最終更新: 2分前")
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .statusGlassCapsule()

        // シンプルスタイル
        Text("データなし")
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .simpleGlassCapsule()
    }
    .padding()
    .background(Color.black)
}

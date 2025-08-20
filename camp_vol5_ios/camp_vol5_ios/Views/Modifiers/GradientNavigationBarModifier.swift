import SwiftUI

// UIKitの外観を制御するためのViewModifier
struct GradientNavigationBarModifier: ViewModifier {
    init(colors: [UIColor], titleColor: UIColor) {
        let appearance = UINavigationBarAppearance()

        // 修正されたヘルパー関数で生成されたグラデーション画像を背景として設定
        appearance.backgroundImage = Self.createGradientImage(colors: colors)

        // タイトルの色を明示的に設定
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

        // ボタンアイテムの色を設定
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.buttonAppearance = buttonAppearance
        appearance.doneButtonAppearance = buttonAppearance
        appearance.backButtonAppearance = buttonAppearance

        // すべての状態（通常時、スクロール時など）に同じ外観を適用
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = titleColor  // 戻るボタンの矢印などの色
    }

    func body(content: Content) -> some View {
        content
    }

    // グラデーションからUIImageを生成するヘルパー関数
    private static func createGradientImage(colors: [UIColor]) -> UIImage {
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cgColors = colors.map { $0.cgColor }
            guard
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: cgColors as CFArray,
                    locations: [0.0, 1.0]
                )
            else { return }

            // グラデーションの方向を左上から右下へ変更
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint.zero,  // 左上 (0, 0)
                end: CGPoint(x: 1, y: 1),  // 右下 (1, 1)
                options: []
            )
        }
    }
}

// Viewに簡単に適用するためのヘルパー拡張
extension View {
    func gradientNavigationBar(colors: [Color], titleColor: Color = .white) -> some View {
        let uiColors = colors.map { UIColor($0) }
        let uiTitleColor = UIColor(titleColor)
        return modifier(
            GradientNavigationBarModifier(colors: uiColors, titleColor: uiTitleColor)
        )
    }
}

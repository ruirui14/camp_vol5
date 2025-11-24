// NavigationBarGradient.swift
// ナビゲーションバー上に表示するグラデーションオーバーレイコンポーネント
// セーフエリアの高さに合わせて動的にサイズ調整し、メインカラーからアクセントカラーへのグラデーションを表示
// ColorThemeManagerと連携して、ユーザーが選択したテーマカラーを反映

import SwiftUI

struct NavigationBarGradient: View {
    @ObservedObject private var themeManager = ColorThemeManager.shared
    let safeAreaHeight: CGFloat?

    init(safeAreaHeight: CGFloat? = nil) {
        self.safeAreaHeight = safeAreaHeight
    }

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            themeManager.mainColor, themeManager.accentColor,
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: safeAreaHeight ?? geometry.safeAreaInsets.top)
                .ignoresSafeArea(.container, edges: .top)
        }
        .frame(height: 0)  // GeometryReaderが親のレイアウトに影響しないようにする
    }
}

#Preview {
    NavigationBarGradient(safeAreaHeight: 44)
}

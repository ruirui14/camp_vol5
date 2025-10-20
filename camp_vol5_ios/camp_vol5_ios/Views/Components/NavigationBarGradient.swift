// NavigationBarGradient.swift
// ナビゲーションバー上に表示するグラデーションオーバーレイコンポーネント
// セーフエリアの高さに合わせて動的にサイズ調整し、メインカラーからアクセントカラーへのグラデーションを表示
// ColorThemeManagerと連携して、ユーザーが選択したテーマカラーを反映

import SwiftUI

struct NavigationBarGradient: View {
    @ObservedObject private var themeManager = ColorThemeManager.shared
    let safeAreaHeight: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [themeManager.mainColor, themeManager.accentColor]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: safeAreaHeight)
            .ignoresSafeArea(.container, edges: .top)
    }
}

#Preview {
    NavigationBarGradient(safeAreaHeight: 44)
}

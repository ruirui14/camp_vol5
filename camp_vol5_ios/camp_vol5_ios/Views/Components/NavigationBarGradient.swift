// NavigationBarGradient.swift
// ナビゲーションバー上に表示するグラデーションオーバーレイコンポーネント
// セーフエリアの高さに合わせて動的にサイズ調整し、メインカラーからアクセントカラーへのグラデーションを表示

import SwiftUI

struct NavigationBarGradient: View {
    let safeAreaHeight: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.main, .accent]),
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

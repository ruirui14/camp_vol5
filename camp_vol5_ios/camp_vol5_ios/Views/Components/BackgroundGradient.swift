// BackgroundGradient.swift
// アプリ全体で使用する背景グラデーションコンポーネント
// 一元管理により、デザインの変更が簡単になる
// ColorThemeManagerと連携して、ユーザーが選択したテーマカラーを反映

import SwiftUI

struct MainAccentGradient: View {
    @ObservedObject private var themeManager = ColorThemeManager.shared

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [themeManager.mainColor, themeManager.accentColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    MainAccentGradient()
}

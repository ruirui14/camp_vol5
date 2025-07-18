// MainAccentGradient.swift
// アプリ全体で使用する背景グラデーションコンポーネント
// 一元管理により、デザインの変更が簡単になる

import SwiftUI

struct MainAccentGradient: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.main, .accent]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    MainAccentGradient()
}

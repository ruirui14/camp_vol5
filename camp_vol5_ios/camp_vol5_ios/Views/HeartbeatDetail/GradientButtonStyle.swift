// Views/Components/GradientButtonStyle.swift
// グラデーションボタンの共通スタイル

import SwiftUI

struct GradientButtonStyle: ViewModifier {
    let colors: [Color]
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content
            .frame(minWidth: 50)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
    }
}

extension View {
    func gradientButtonStyle(colors: [Color], isDisabled: Bool = false) -> some View {
        modifier(GradientButtonStyle(colors: colors, isDisabled: isDisabled))
    }
}

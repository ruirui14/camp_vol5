// ThemeColor.swift
// カスタマイズ可能なテーマカラーを環境値として注入するための拡張
// ColorThemeManagerと連携してアプリ全体のカラーを動的に変更

import SwiftUI

// MARK: - Environment Key

private struct ThemeMainColorKey: EnvironmentKey {
    static let defaultValue: Color = Color("main")
}

extension EnvironmentValues {
    var themeMainColor: Color {
        get { self[ThemeMainColorKey.self] }
        set { self[ThemeMainColorKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// ColorThemeManagerから動的にテーマカラーを注入する
    func applyThemeColors() -> some View {
        self.environment(\.themeMainColor, ColorThemeManager.shared.mainColor)
    }
}

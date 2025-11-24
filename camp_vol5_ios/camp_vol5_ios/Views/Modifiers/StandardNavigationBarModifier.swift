// Views/Modifiers/StandardNavigationBarModifier.swift
// 標準的なNavigationBarスタイルを提供するカスタムViewModifier
// 複数画面で使用される共通のNavigationBar設定を統一
// 用途: 設定画面、詳細画面など通常のNavigationBarを持つ画面

import SwiftUI

/// 標準的なNavigationBarスタイルを適用するモディファイア
struct StandardNavigationBarModifier: ViewModifier {
    /// NavigationBarの表示モード
    let displayMode: NavigationBarItem.TitleDisplayMode
    /// 背景色（nilの場合はシステムデフォルト）
    let backgroundColor: Color?
    /// 背景の可視性
    let backgroundVisibility: Visibility

    init(
        displayMode: NavigationBarItem.TitleDisplayMode = .inline,
        backgroundColor: Color? = Color(.systemBackground),
        backgroundVisibility: Visibility = .visible
    ) {
        self.displayMode = displayMode
        self.backgroundColor = backgroundColor
        self.backgroundVisibility = backgroundVisibility
    }

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(backgroundVisibility, for: .navigationBar)
            .apply { view in
                if let backgroundColor = backgroundColor {
                    view.toolbarBackground(backgroundColor, for: .navigationBar)
                } else {
                    view
                }
            }
    }
}

/// 透明NavigationBarスタイルを適用するモディファイア
struct TransparentNavigationBarModifier: ViewModifier {
    /// NavigationBarの表示モード
    let displayMode: NavigationBarItem.TitleDisplayMode

    init(displayMode: NavigationBarItem.TitleDisplayMode = .inline) {
        self.displayMode = displayMode
    }

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

extension View {
    /// 標準的なNavigationBarスタイルを適用
    /// - Parameters:
    ///   - displayMode: タイトルの表示モード（デフォルト: .inline）
    ///   - backgroundColor: 背景色（デフォルト: システム背景色、nilの場合は設定しない）
    ///   - backgroundVisibility: 背景の可視性（デフォルト: .visible）
    /// - Returns: 標準NavigationBarスタイルが適用されたView
    func standardNavigationBar(
        displayMode: NavigationBarItem.TitleDisplayMode = .inline,
        backgroundColor: Color? = Color(.systemBackground),
        backgroundVisibility: Visibility = .visible
    ) -> some View {
        modifier(
            StandardNavigationBarModifier(
                displayMode: displayMode,
                backgroundColor: backgroundColor,
                backgroundVisibility: backgroundVisibility
            )
        )
    }

    /// 透明なNavigationBarスタイルを適用（グラデーション背景やカスタム背景用）
    /// - Parameter displayMode: タイトルの表示モード（デフォルト: .inline）
    /// - Returns: 透明NavigationBarスタイルが適用されたView
    func transparentNavigationBar(
        displayMode: NavigationBarItem.TitleDisplayMode = .inline
    ) -> some View {
        modifier(TransparentNavigationBarModifier(displayMode: displayMode))
    }

    /// 条件付きでViewModifierを適用するヘルパー
    fileprivate func apply<V: View>(@ViewBuilder _ transform: (Self) -> V) -> some View {
        transform(self)
    }
}

#Preview("Standard NavigationBar") {
    NavigationStack {
        List {
            Text("Item 1")
            Text("Item 2")
            Text("Item 3")
        }
        .navigationTitle("設定")
        .standardNavigationBar()
    }
}

#Preview("Transparent NavigationBar") {
    NavigationStack {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Text("コンテンツ")
                .foregroundColor(.white)
        }
        .navigationTitle("詳細")
        .transparentNavigationBar()
    }
}

// Views/Auth/Components/ErrorBanner.swift
// エラーバナー - 後方互換性のためのラッパー
// MessageBannerの.errorタイプを使用した便利なエイリアス

import SwiftUI

/// エラーバナーコンポーネント（後方互換性のため）
/// 内部的には MessageBanner.error を使用
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        MessageBanner.error(message: message, onDismiss: onDismiss)
    }
}

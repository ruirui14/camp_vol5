// Views/Components/ModernTextFieldStyle.swift
// 共有のモダンテキストフィールドスタイル - 統一されたテキストフィールドの見た目を提供
// SwiftUIベストプラクティスに従い、アプリ全体で再利用可能な設定として実装

import SwiftUI

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
            )
            .font(.body)
    }
}

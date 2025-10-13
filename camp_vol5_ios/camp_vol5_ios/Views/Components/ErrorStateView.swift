// Views/Components/ErrorStateView.swift
// エラー状態表示コンポーネント - エラーメッセージと再試行ボタンを表示
// SwiftUIベストプラクティスに従い、再利用可能なエラー表示として設計

import SwiftUI

struct ErrorStateView: View {
    let errorMessage: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(errorMessage)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()

            Button("再試行") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ErrorStateView(
        errorMessage: "データの読み込みに失敗しました",
        onRetry: {}
    )
    .background(Color.gray.opacity(0.1))
}

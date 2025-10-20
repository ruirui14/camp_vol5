// Views/Settings/TermsOfServiceView.swift
// 利用規約画面 - MarkdownUIを使って利用規約を表示
// Resources/TERMS_OF_SERVICE.mdファイルから内容を読み込んでMarkdown形式で表示

import MarkdownUI
import SwiftUI

struct TermsOfServiceView: View {
    @State private var markdownContent: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Text("エラーが発生しました")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                Markdown(markdownContent)
                    .markdownTextStyle {
                        FontSize(14)
                    }
                    .padding()
            }
        }
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMarkdown()
        }
    }

    private func loadMarkdown() {
        guard let url = Bundle.main.url(forResource: "TERMS_OF_SERVICE", withExtension: "md") else {
            errorMessage = "ファイルが見つかりません"
            isLoading = false
            return
        }

        do {
            markdownContent = try String(contentsOf: url, encoding: .utf8)
            isLoading = false
        } catch {
            errorMessage = "ファイルの読み込みに失敗しました: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}

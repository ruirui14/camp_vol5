// Views/Components/StreamUrlInputSheet.swift
// 配信URL入力シート
// ユーザーが配信URLをペーストして設定できるUI

import SwiftUI

struct StreamUrlInputSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var streamUrl: String
    @State private var inputText: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("配信URLを入力してください")
                    .font(.headline)
                    .padding(.top)

                TextField("配信URLをペースト", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.horizontal)

                Text("YouTube、Twitch、ニコニコ動画などの配信URLを貼り付けてください")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("配信URL設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("設定") {
                        streamUrl = inputText
                        dismiss()
                    }
                    .disabled(inputText.isEmpty)
                }
            }
            .onAppear {
                inputText = streamUrl
            }
        }
    }
}

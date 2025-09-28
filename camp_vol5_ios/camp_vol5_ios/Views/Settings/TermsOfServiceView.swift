// Views/Settings/TermsOfServiceView.swift
// 利用規約画面 - アプリの利用規約を表示
// SwiftUIベストプラクティスに従い、スクロール可能なコンテンツとして実装

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("最終更新日: 2024年1月1日")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    TermsSection(
                        title: "第1条（利用規約の適用）",
                        content:
                            "本利用規約は、Heart Beat Monitorアプリケーション（以下「本アプリ」といいます）の利用に関して適用されます。本アプリを利用することにより、お客様は本規約に同意したものとみなします。"
                    )

                    TermsSection(
                        title: "第2条（アプリの目的）",
                        content:
                            "本アプリは、心拍数をリアルタイムで共有し、健康管理とコミュニケーションを支援することを目的としています。医療診断や治療を目的としたものではありません。"
                    )

                    TermsSection(
                        title: "第3条（利用者の義務）",
                        content:
                            "利用者は以下の行為を行ってはなりません：\n• 本アプリを商用目的で利用すること\n• 他の利用者に迷惑をかける行為\n• システムの正常な動作を妨げる行為\n• 個人情報を不正に取得する行為"
                    )

                    TermsSection(
                        title: "第4条（プライバシー）",
                        content:
                            "本アプリは、お客様の心拍数データを収集・処理します。収集されたデータは、アプリの機能提供のためにのみ使用され、第三者に提供されることはありません。"
                    )

                    TermsSection(
                        title: "第5条（データの保存期間）",
                        content: "心拍数データは5分間のみ保存され、その後自動的に削除されます。ユーザー情報は、アカウントが削除されるまで保存されます。"
                    )

                    TermsSection(
                        title: "第6条（免責事項）",
                        content: "本アプリの利用により生じた損害について、開発者は一切の責任を負いません。本アプリは現状有姿で提供され、動作の保証はありません。"
                    )

                    TermsSection(
                        title: "第7条（利用規約の変更）",
                        content: "開発者は、必要に応じて本利用規約を変更することができます。変更後の利用規約は、本アプリ内での表示をもって効力を生じます。"
                    )

                    TermsSection(
                        title: "第8条（準拠法）",
                        content: "本利用規約は日本国法に準拠し、本アプリに関する紛争は、東京地方裁判所を第一審の専属管轄裁判所とします。"
                    )
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        TermsOfServiceView()
    }
}
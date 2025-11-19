// Views/Components/IconLabelButtonContent.swift
// ボタン内のアイコンとラベルの共通コンポーネント
// 編集画面のコントロールボタンで使用

import SwiftUI

struct IconLabelButtonContent: View {
    let icon: String
    let label: String
    let iconColor: Color
    let labelColor: Color
    let fontSize: Font

    init(
        icon: String,
        label: String,
        iconColor: Color = .white,
        labelColor: Color = .white,
        fontSize: Font = .title3
    ) {
        self.icon = icon
        self.label = label
        self.iconColor = iconColor
        self.labelColor = labelColor
        self.fontSize = fontSize
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(fontSize)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(labelColor)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        IconLabelButtonContent(icon: "photo.on.rectangle.angled", label: "写真を選択")
            .gradientButtonStyle(colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.7)])

        IconLabelButtonContent(icon: "paintpalette", label: "背景色")
            .gradientButtonStyle(colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.7)])
    }
    .padding()
    .background(Color.gray)
}

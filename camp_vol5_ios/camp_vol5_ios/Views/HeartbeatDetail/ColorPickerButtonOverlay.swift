// Views/HeartbeatDetail/ColorPickerButtonOverlay.swift
// ColorPickerを透明にしてボタンに重ねるコンポーネント
// 背景色選択ボタンで使用

import SwiftUI

struct ColorPickerButtonOverlay: View {
    @Binding var selectedColor: Color
    let buttonContent: AnyView
    let gradientColors: [Color]

    init(
        selectedColor: Binding<Color>,
        gradientColors: [Color],
        @ViewBuilder buttonContent: () -> some View
    ) {
        self._selectedColor = selectedColor
        self.gradientColors = gradientColors
        self.buttonContent = AnyView(buttonContent())
    }

    var body: some View {
        ZStack {
            buttonContent
                .gradientButtonStyle(colors: gradientColors)

            ColorPicker("", selection: $selectedColor)
                .labelsHidden()
                .scaleEffect(CGSize(width: 2, height: 2))
                .opacity(0.011)
                .allowsHitTesting(true)
        }
    }
}

#Preview {
    @Previewable @State var selectedColor: Color = .clear

    ColorPickerButtonOverlay(
        selectedColor: $selectedColor,
        gradientColors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.7)]
    ) {
        IconLabelButtonContent(icon: "paintpalette", label: "背景色")
    }
    .padding()
    .background(Color.gray)
}

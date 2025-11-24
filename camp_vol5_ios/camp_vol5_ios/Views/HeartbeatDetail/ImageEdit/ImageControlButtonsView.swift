// Views/HeartbeatDetail/ImageEdit/ImageControlButtonsView.swift
// 画像編集コントロールボタンコンポーネント
// 写真選択、サイズ調整、リセット、背景色選択ボタンを提供

import SwiftUI

/// 画像編集のコントロールボタン群を管理するビュー
struct ImageControlButtonsView: View {
    // MARK: - Properties

    @Binding var showingPhotoPicker: Bool
    @Binding var showingHeartSizeSlider: Bool
    @Binding var selectedBackgroundColor: Color
    let isImageSelected: Bool
    let onResetPosition: () -> Void

    // MARK: - Body

    var body: some View {
        VStack {
            Spacer()
            buttonRow
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    // MARK: - Subviews

    /// コントロールボタンの行
    private var buttonRow: some View {
        HStack(alignment: .top, spacing: 20) {
            // 写真選択ボタン
            photoPickerButton

            // ハートサイズ調整ボタン
            heartSizeButton

            // 位置リセットボタン
            resetPositionButton

            // 背景色選択ボタン
            backgroundColorButton
        }
    }

    /// 写真選択ボタン
    private var photoPickerButton: some View {
        Button {
            showingPhotoPicker = true
        } label: {
            IconLabelButtonContent(icon: "photo.on.rectangle.angled", label: "写真を選択")
        }
        .gradientButtonStyle(colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.7)])
    }

    /// ハートサイズ調整ボタン
    private var heartSizeButton: some View {
        Button {
            showingHeartSizeSlider = true
        } label: {
            IconLabelButtonContent(icon: "heart.text.square", label: "サイズ調整")
        }
        .gradientButtonStyle(
            colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
            isDisabled: !isImageSelected
        )
        .disabled(!isImageSelected)
    }

    /// 位置リセットボタン
    private var resetPositionButton: some View {
        Button(action: onResetPosition) {
            IconLabelButtonContent(icon: "arrow.counterclockwise", label: "位置リセット")
        }
        .gradientButtonStyle(
            colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.7)],
            isDisabled: !isImageSelected
        )
        .disabled(!isImageSelected)
    }

    /// 背景色選択ボタン
    private var backgroundColorButton: some View {
        ColorPickerButtonOverlay(
            selectedColor: $selectedBackgroundColor,
            gradientColors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.7)]
        ) {
            IconLabelButtonContent(icon: "paintpalette", label: "背景色")
        }
    }
}

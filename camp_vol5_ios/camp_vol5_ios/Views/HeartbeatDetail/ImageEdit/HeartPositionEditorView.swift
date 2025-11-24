// Views/HeartbeatDetail/ImageEdit/HeartPositionEditorView.swift
// ハートの位置とサイズ調整コンポーネント
// ドラッグ可能なハートとサイズ調整スライダーを提供

import SwiftUI

/// ハートの位置とサイズを調整するビュー
struct HeartPositionEditorView: View {
    // MARK: - Properties

    @Binding var tempHeartOffset: CGSize
    @Binding var lastHeartOffset: CGSize
    @Binding var tempHeartSize: CGFloat
    @Binding var showingHeartSizeSlider: Bool
    let isImageSelected: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            // ドラッグ可能なハート（画像が選択されている場合のみ表示）
            if isImageSelected {
                draggableHeart
            }

            // ハートサイズ調整スライダー
            if showingHeartSizeSlider {
                heartSizeSlider
            }
        }
    }

    // MARK: - Subviews

    /// ドラッグ可能なハートビュー
    private var draggableHeart: some View {
        HeartAnimationView(
            bpm: 0,  // 編集画面では静止
            heartSize: tempHeartSize,
            showBPM: true,
            enableHaptic: false,
            heartColor: .red
        )
        .offset(tempHeartOffset)
        .ignoresSafeArea()
        .gesture(
            DragGesture()
                .onChanged { value in
                    tempHeartOffset = CGSize(
                        width: lastHeartOffset.width + value.translation.width,
                        height: lastHeartOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastHeartOffset = tempHeartOffset
                }
        )
    }

    /// ハートサイズ調整スライダー
    private var heartSizeSlider: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Text("ハートサイズ調整")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)

                HStack {
                    Text("小")
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)

                    Slider(value: $tempHeartSize, in: 60...200, step: 5)
                        .accentColor(.white)

                    Text("大")
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }

                Text("サイズ: \(Int(tempHeartSize))")
                    .font(.caption)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)

                Button("完了") {
                    showingHeartSizeSlider = false
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.3))
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.7))
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 150)  // ボタンとの重複を避ける
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: showingHeartSizeSlider)
    }
}

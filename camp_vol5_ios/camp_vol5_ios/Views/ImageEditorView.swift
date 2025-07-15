// Views/ImageEditorView.swift

import SwiftUI

// 画像編集用のモーダルビュー

struct ImageEditorView: View {
    let image: UIImage
    @Binding var offset: CGSize
    @Binding var scale: CGFloat
    @Binding var lastScale: CGFloat
    @Binding var heartOffset: CGSize
    let onApply: () -> Void
    let onCancel: () -> Void
    @State private var lastOffset: CGSize = .zero
    @State private var lastHeartOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Group {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(scale)
                        .offset(offset)
                        .ignoresSafeArea()
                        .overlay(
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                        )
                }
                .gesture(
                    SimultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { value in
                                lastOffset = offset
                            },
                        MagnificationGesture()
                            .onChanged { value in
                                let newScale = lastScale * value
                                scale = max(0.5, min(newScale, 3.0))  // 0.5x から 3.0x に制限
                            }
                            .onEnded { value in
                                lastScale = scale
                            }
                    )
                )
                VStack(spacing: 20) {
                    Spacer()
                    Spacer()
                    Spacer()
                    VStack(spacing: 8) {
                        ZStack {
                            Image("heart_beat")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 105, height: 92)
                                .clipShape(Circle())
                            Text("--")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        }
                        Text("No data available")
                            .font(.caption)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                    }
                    .offset(heartOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                heartOffset = CGSize(
                                    width: lastHeartOffset.width + value.translation.width,
                                    height: lastHeartOffset.height + value.translation.height
                                )
                            }
                            .onEnded { value in
                                lastHeartOffset = heartOffset
                            }
                    )
                    // エラーメッセージの領域（空だが構造を一致させるため）
                    Color.clear
                        .frame(height: 0)
                    Spacer()
                }
                .padding()
                .allowsHitTesting(true)
                VStack {
                    HStack {
                        Button("キャンセル") {
                            onCancel()
                        }
                        .foregroundColor(.white)
                        Spacer()
                        Text("画像を調整")
                            .foregroundColor(.white)
                            .font(.headline)
                        Spacer()
                        Button("適用") {
                            onApply()
                        }
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)  // セーフエリアを考慮してトップパディングを増加
                    .background(Color.black.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(true)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            lastHeartOffset = heartOffset
        }
    }
}
struct ImageEditorView_Previews: PreviewProvider {
    static var previews: some View {
        ImageEditorView(
            image: UIImage(systemName: "photo")!,
            offset: .constant(.zero),
            scale: .constant(1.0),
            lastScale: .constant(1.0),
            heartOffset: .constant(.zero),
            onApply: {},
            onCancel: {}
        )
    }
}

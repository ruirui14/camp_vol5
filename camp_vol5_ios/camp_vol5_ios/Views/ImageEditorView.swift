// Views/ImageEditorView.swift
// 画像編集用のモーダルビュー - 修正版
import SwiftUI

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
                // 背景画像レイヤー
                backgroundImageLayer(geometry: geometry)

                // ハートエリア
                heartAreaLayer
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .onAppear {
                lastOffset = offset
                lastHeartOffset = heartOffset
            }
        }
        .ignoresSafeArea()
        .overlay(controlsOverlay, alignment: .top)
    }

    private func backgroundImageLayer(geometry: GeometryProxy) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(
                width: geometry.size.width * scale,
                height: geometry.size.height * scale
            )
            .position(
                x: geometry.size.width / 2 + offset.width,
                y: geometry.size.height / 2 + offset.height
            )
            .clipped()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(
                Color.black.opacity(0.3)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            )
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        },
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = lastScale * value
                            scale = max(0.5, min(newScale, 3.0))
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
            )
    }

    private var heartAreaLayer: some View {
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
                    .onEnded { _ in
                        lastHeartOffset = heartOffset
                    }
            )
            Spacer()
        }
        .padding()
        .padding(.top, 118)  // NavigationBar分の補正
    }

    private var controlsOverlay: some View {
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
            .padding(.top, 60)
            .padding(.bottom, 20)
            .background(Color.black.opacity(0.5))

            Spacer()
        }
    }
}

struct HeartbeatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HeartbeatDetailView(userId: "preview_user_id")
            .environmentObject(AuthenticationManager())
    }
}

import SwiftUI

// 画像編集用のモーダルビュー
struct ImageEditorView: View {
    let image: UIImage
    @Binding var offset: CGSize
    @Binding var scale: CGFloat
    @Binding var lastScale: CGFloat
    let onApply: () -> Void
    let onCancel: () -> Void
    
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color.black.ignoresSafeArea()
                
                // 編集可能な画像
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .clipped()
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
                                    scale = max(0.5, min(newScale, 3.0)) // 0.5x から 3.0x に制限
                                }
                                .onEnded { value in
                                    lastScale = scale
                                }
                        )
                    )
                
                // オーバーレイ（ジェスチャーを妨げないように画像の外に配置）
                ZStack {
                    Color.clear
                    VStack {
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 100)
                        Spacer()
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 100)
                    }
                }
                .allowsHitTesting(false)
                
                // 操作説明
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("ドラッグで移動")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("ピンチで拡大縮小")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding()
                    }
                }
            }
            .navigationTitle("画像を調整")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    onCancel()
                }
                .foregroundColor(.white),
                trailing: Button("適用") {
                    onApply()
                }
                .foregroundColor(.white)
                .fontWeight(.bold)
            )
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
            onApply: {},
            onCancel: {}
        )
    }
}
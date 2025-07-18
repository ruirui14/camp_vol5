import SwiftUI
import PhotosUI

struct ImageEditView: View {
    @Binding var image: UIImage?
    @Binding var imageOffset: CGSize
    @Binding var imageScale: CGFloat
    let onApply: () -> Void
    @State private var tempOffset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var tempScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var heartOffset = CGSize.zero
    @State private var lastHeartOffset = CGSize.zero
    @State private var showingPhotoPicker = false
    @Environment(\.presentationMode) var presentationMode

    private let persistenceManager = PersistenceManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // 白い背景（表示画面と同じ）
                Color.white
                    .ignoresSafeArea()

                // 画像表示とジェスチャー
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(tempScale)
                        .offset(tempOffset)
                        .ignoresSafeArea()
                        .gesture(
                            SimultaneousGesture(
                                // ドラッグジェスチャー
                                DragGesture()
                                    .onChanged { value in
                                        tempOffset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { value in
                                        lastOffset = tempOffset
                                    },
                                // ズームジェスチャー
                                MagnificationGesture()
                                    .onChanged { value in
                                        tempScale = lastScale * value
                                    }
                                    .onEnded { value in
                                        lastScale = tempScale
                                        // 最小・最大スケールの制限
                                        if tempScale < 0.5 {
                                            tempScale = 0.5
                                            lastScale = 0.5
                                        } else if tempScale > 5.0 {
                                            tempScale = 5.0
                                            lastScale = 5.0
                                        }
                                    }
                            )
                        )
                }

                // コントロールボタン（固定位置）
                VStack {
                    Spacer()
                    controlButtons
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .overlay(
                // ドラッグ可能なハートビュー（HeartbeatDetailViewと同じ位置）
                ZStack {
                    Image("heart_beat")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 105, height: 92)
                        .clipShape(Circle())
                    Text("--")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.8), radius: 2, x: 0, y: 1)
                }
                .offset(heartOffset)
                .ignoresSafeArea()
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
                ),
                alignment: .center
            )
            .whiteCapsuleTitle("画像を編集中")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackgroundTransparent()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("適用") {
                        // 編集内容を適用
                        imageOffset = tempOffset
                        imageScale = tempScale

                        // ハートの位置を保存
                        persistenceManager.saveHeartPosition(heartOffset)

                        // 画像の変形情報を直接保存
                        persistenceManager.saveImageTransform(
                            offset: tempOffset, scale: tempScale)

                        onApply()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(selectedImage: $image)
        }
        .onAppear {
            // 永続化されたデータを再読み込み
            let transform = persistenceManager.loadImageTransform()
            imageOffset = transform.offset
            imageScale = transform.scale

            // 現在の状態を編集画面に反映
            tempOffset = transform.offset
            lastOffset = transform.offset
            tempScale = transform.scale
            lastScale = transform.scale

            // ハートの位置を読み込み
            let heartPosition = persistenceManager.loadHeartPosition()
            heartOffset = heartPosition
            lastHeartOffset = heartPosition
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(alignment: .top, spacing: 40) {
            Button(action: {
                showingPhotoPicker = true
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundColor(.white)
                        .font(.title3)
                    Text("写真を選択")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                }
                .frame(minWidth: 80)
            }

            Button(action: resetImagePosition) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.white)
                        .font(.title3)
                    Text("リセット")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                }
                .frame(minWidth: 80)
                .opacity(image != nil ? 1.0 : 0.5)
            }
            .disabled(image == nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetImagePosition() {
        withAnimation(.spring()) {
            tempOffset = .zero
            lastOffset = .zero
            tempScale = 1.0
            lastScale = 1.0
            heartOffset = .zero
            lastHeartOffset = .zero
        }
    }
}

#Preview {
    ImageEditView(
        image: .constant(UIImage(systemName: "photo")),
        imageOffset: .constant(CGSize.zero),
        imageScale: .constant(1.0),
        onApply: {}
    )
}

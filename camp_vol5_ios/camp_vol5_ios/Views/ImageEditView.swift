import PhotosUI
import SwiftUI

struct ImageEditView: View {
    @Binding var image: UIImage?
    @Binding var imageOffset: CGSize
    @Binding var imageScale: CGFloat
    @Binding var imageRotation: Double
    @Binding var heartOffset: CGSize
    @Binding var heartSize: CGFloat
    let onApply: () -> Void
    let userId: String
    @State private var tempOffset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var tempScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var tempRotation: Double = 0.0
    @State private var lastRotation: Double = 0.0
    @State private var tempHeartOffset = CGSize.zero
    @State private var lastHeartOffset = CGSize.zero
    @State private var tempHeartSize: CGFloat = 105.0
    @State private var showingPhotoPicker = false
    @State private var showingHeartSizeSlider = false
    @State private var selectedBackgroundColor: Color = .clear
    @Environment(\.presentationMode) var presentationMode
    @State private var tempColor: Color = .clear
    @State private var imageData: Data?
    @State private var isAnimatedImage: Bool = false

    private let persistenceManager = PersistenceManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色選択またはデフォルトグラデーション
                if selectedBackgroundColor != Color.clear {
                    selectedBackgroundColor
                        .ignoresSafeArea()
                } else {
                    MainAccentGradient()
                }

                // 画像表示とジェスチャー（GIF対応）
                if let data = imageData, isAnimatedImage {
                    // GIFアニメーションの場合
                    ZStack {
                        AnimatedImageView(imageData: data, contentMode: .scaleAspectFit)
                            .scaleEffect(tempScale)
                            .rotationEffect(.degrees(tempRotation))
                            .offset(tempOffset)
                            .ignoresSafeArea()

                        // ジェスチャー用の透明レイヤー
                        Color.clear
                            .contentShape(Rectangle())
                            .ignoresSafeArea()
                            .gesture(
                                SimultaneousGesture(
                                    SimultaneousGesture(
                                        dragGesture,
                                        magnificationGesture
                                    ),
                                    rotationGesture
                                )
                            )
                    }
                } else if let image = image {
                    // 通常の画像の場合
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(tempScale)
                        .rotationEffect(.degrees(tempRotation))
                        .offset(tempOffset)
                        .ignoresSafeArea()
                        .gesture(
                            SimultaneousGesture(
                                SimultaneousGesture(
                                    dragGesture,
                                    magnificationGesture
                                ),
                                rotationGesture
                            )
                        )
                } else {
                    // 画像が選択されていない場合のプレースホルダー
                    VStack(spacing: 20) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))

                        Text("写真を選択してください")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
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
                // ドラッグ可能なハートビュー（画像が選択されている場合のみ表示）
                Group {
                    if image != nil {
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
                },
                alignment: .center
            )
            .overlay(
                // ハートサイズ調整スライダー
                Group {
                    if showingHeartSizeSlider {
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
                                        .shadow(
                                            color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1
                                        )

                                    Slider(value: $tempHeartSize, in: 60...200, step: 5)
                                        .accentColor(.white)
                                        .onChange(of: tempHeartSize) { _, _ in
                                            // 一時的な値として保持するのみ（適用時に保存）
                                        }

                                    Text("大")
                                        .foregroundColor(.white)
                                        .shadow(
                                            color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1
                                        )
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
            )
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

                ToolbarItem(placement: .principal) {
                    WhiteCapsuleTitle(title: "画像を編集中")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("適用") {
                        // 編集内容を適用
                        imageOffset = tempOffset
                        imageScale = tempScale
                        imageRotation = tempRotation

                        // ハートの位置とサイズを適用
                        heartOffset = tempHeartOffset
                        heartSize = tempHeartSize

                        // ハートの位置を保存
                        persistenceManager.saveHeartPosition(tempHeartOffset, userId: userId)

                        // ハートのサイズを保存
                        persistenceManager.saveHeartSize(tempHeartSize, userId: userId)

                        // 画像の変形情報を直接保存（回転も含む）
                        persistenceManager.saveImageTransform(
                            offset: tempOffset,
                            scale: tempScale,
                            rotation: tempRotation,
                            userId: userId
                        )

                        // 背景色を保存
                        persistenceManager.saveBackgroundColor(tempColor, userId: userId)

                        // 画像データを保存（GIF対応）
                        if let image = image {
                            persistenceManager.saveBackgroundImage(
                                image,
                                userId: userId,
                                imageData: imageData
                            )
                        }

                        onApply()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .disabled(image == nil)
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            GifPhotoPickerView(selectedImage: $image, selectedImageData: $imageData)
        }
        .onAppear {
            // 背景色を読み込み
            selectedBackgroundColor = persistenceManager.loadBackgroundColor(userId: userId)

            // アニメーション画像かどうかを確認
            isAnimatedImage = persistenceManager.isAnimatedImage(userId: userId)

            // 画像データを読み込み（GIF対応）
            // 画像が既に選択されている場合のみ読み込む（新規選択時は不要）
            if image != nil, isAnimatedImage {
                if let data = persistenceManager.loadBackgroundImageData(userId: userId) {
                    imageData = data
                }
            } else {
                // アニメーション画像でない場合はimageDataをクリア
                imageData = nil
            }

            // 常にBindingから渡された値を使用する
            // これにより、HeartbeatDetailViewから渡された現在の状態が正しく反映される
            tempOffset = imageOffset
            lastOffset = imageOffset
            tempScale = imageScale
            lastScale = imageScale
            tempRotation = imageRotation
            lastRotation = imageRotation

            // ハートの位置とサイズをtempに初期化
            tempHeartOffset = heartOffset
            lastHeartOffset = heartOffset
            tempHeartSize = heartSize
        }
        .onChange(of: selectedBackgroundColor) { _, newColor in
            // 背景色が変更されたときに仮保存
            tempColor = newColor
        }
        .onChange(of: imageData) { _, newData in
            // 画像データが変更されたときにGIFかどうかを判定
            if let data = newData, data.count > 3 {
                // GIFのマジックナンバーをチェック（"GIF"）
                let header = [UInt8](data.prefix(3))
                isAnimatedImage = (header == [0x47, 0x49, 0x46])
            } else {
                isAnimatedImage = false
            }
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(alignment: .top, spacing: 20) {
            Button {
                showingPhotoPicker = true
            } label: {
                IconLabelButtonContent(icon: "photo.on.rectangle.angled", label: "写真を選択")
            }
            .gradientButtonStyle(colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.7)])

            Button {
                showingHeartSizeSlider = true
            } label: {
                IconLabelButtonContent(icon: "heart.text.square", label: "サイズ調整")
            }
            .gradientButtonStyle(
                colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                isDisabled: image == nil
            )
            .disabled(image == nil)

            Button(action: resetImagePosition) {
                IconLabelButtonContent(icon: "arrow.counterclockwise", label: "位置リセット")
            }
            .gradientButtonStyle(
                colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.7)],
                isDisabled: image == nil
            )
            .disabled(image == nil)

            ColorPickerButtonOverlay(
                selectedColor: $selectedBackgroundColor,
                gradientColors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.7)]
            ) {
                IconLabelButtonContent(icon: "paintpalette", label: "背景色")
            }
        }
    }

    // MARK: - Helper Methods

    private func resetImagePosition() {
        withAnimation(.spring()) {
            tempOffset = .zero
            lastOffset = .zero
            tempScale = 1.0
            lastScale = 1.0
            tempRotation = 0.0
            lastRotation = 0.0
            tempHeartOffset = .zero
            lastHeartOffset = .zero
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                tempOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = tempOffset
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                tempScale = lastScale * value
            }
            .onEnded { _ in
                lastScale = tempScale
                if tempScale < 0.5 {
                    tempScale = 0.5
                    lastScale = 0.5
                } else if tempScale > 5.0 {
                    tempScale = 5.0
                    lastScale = 5.0
                }
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                tempRotation = lastRotation + value.degrees
            }
            .onEnded { _ in
                lastRotation = tempRotation
            }
    }
}

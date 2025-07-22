import PhotosUI
import SwiftUI

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
    @State private var heartSize: CGFloat = 105.0
    @State private var showingPhotoPicker = false
    @State private var showingHeartSizeSlider = false
    @State private var selectedBackgroundColor: Color = Color.clear
    @Environment(\.presentationMode) var presentationMode

    private let persistenceManager = PersistenceManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // 背景色選択またはデフォルトグラデーション
                if selectedBackgroundColor != Color.clear {
                    selectedBackgroundColor
                        .ignoresSafeArea()
                } else {
                    MainAccentGradient()
                }

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
                            heartSize: heartSize,
                            showBPM: true,
                            enableHaptic: false,
                            heartColor: .red
                        )
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
                                            color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)

                                    Slider(value: $heartSize, in: 60...200, step: 5)
                                        .accentColor(.white)
                                        .onChange(of: heartSize) { newSize in
                                            persistenceManager.saveHeartSize(newSize)
                                        }

                                    Text("大")
                                        .foregroundColor(.white)
                                        .shadow(
                                            color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                                }

                                Text("サイズ: \(Int(heartSize))")
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
                    WhiteCapsuleTitle(title: "画像を編集中" ?? "読み込み中...")
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
                    .disabled(image == nil)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(selectedImage: $image)
        }
        .onAppear {
            // ハートのサイズを読み込み
            heartSize = persistenceManager.loadHeartSize()

            // 背景色を読み込み
            selectedBackgroundColor = persistenceManager.loadBackgroundColor()

            // 永続化されたデータを再読み込み（画像がある場合のみ）
            if image != nil {
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
        .onChange(of: selectedBackgroundColor) { _, newColor in
            // 背景色が変更されたときに保存
            persistenceManager.saveBackgroundColor(newColor)
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(alignment: .top, spacing: 20) {
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
                .frame(minWidth: 50)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.pink.opacity(0.8),
                                    Color.purple.opacity(0.7),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }

            Button(action: {
                showingHeartSizeSlider = true
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .foregroundColor(.white)
                        .font(.title3)
                    Text("サイズ調整")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                }
                .frame(minWidth: 50)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.red.opacity(0.8),
                                    Color.orange.opacity(0.7),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .opacity(image != nil ? 1.0 : 0.5)
            }
            .disabled(image == nil)

            Button(action: resetImagePosition) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.white)
                        .font(.title3)
                    Text("リセット")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                }
                .frame(minWidth: 50)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.8),
                                    Color.cyan.opacity(0.7),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .opacity(image != nil ? 1.0 : 0.5)
            }
            .disabled(image == nil)

            ZStack {

                Button(action: {}) {
                    VStack(spacing: 8) {
                        Image(systemName: "paintpalette")
                            .foregroundColor(.white)
                            .font(.title3)
                        Text("背景色")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .frame(minWidth: 50)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.yellow.opacity(0.8),
                                        Color.orange.opacity(0.7),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .disabled(true)

                ColorPicker("", selection: $selectedBackgroundColor)
                    .labelsHidden()
                    .scaleEffect(CGSize(width: 2, height: 2))
                    .opacity(0.011)
                    .allowsHitTesting(true)

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
            heartOffset = .zero
            lastHeartOffset = .zero
        }
    }
}

// MARK: - Color Palette View
struct ColorPaletteView: View {
    @Binding var selectedColor: Color
    @Environment(\.presentationMode) var presentationMode

    private let colors: [Color] = [
        .clear, .red, .orange, .yellow, .green, .mint, .teal, .cyan,
        .blue, .indigo, .purple, .pink, .brown, .gray, .black, .white,
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("背景色を選択")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            print("🎨 色選択: \(color)")
                            selectedColor = color
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    color == .clear
                                        ? LinearGradient(
                                            colors: [.main, .accent], startPoint: .topLeading,
                                            endPoint: .bottomTrailing)
                                        : LinearGradient(
                                            colors: [color], startPoint: .center, endPoint: .center)
                                )
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(
                                            selectedColor == color
                                                ? Color.blue : Color.gray.opacity(0.3),
                                            lineWidth: selectedColor == color ? 3 : 1)
                                )
                                .overlay(
                                    color == .clear
                                        ? Text("デフォルト")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .shadow(color: .black, radius: 1) : nil
                                )
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("カラーパレット")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing:
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
            )
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

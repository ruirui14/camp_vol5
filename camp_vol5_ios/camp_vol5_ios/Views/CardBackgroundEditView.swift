// CardBackgroundEditView.swift
// UserHeartbeatCardの背景画像を編集するビュー
// 透過画像をドラッグ・ズームで配置し、カード範囲内では透過を解除

import PhotosUI
import SwiftUI

struct CardBackgroundEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var backgroundImageManager: BackgroundImageManager
    @State private var selectedImage: UIImage?
    @State private var showingPhotoPicker = false
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var imageScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var cardFrame: CGRect = .zero
    @State private var selectedBackgroundColor: Color = Color.clear

    // UserHeartbeatCardと同じサイズ
    private let cardSize = CGSize(width: 370, height: 120)
    let userId: String
    init(userId: String) {
        self.userId = userId
        _backgroundImageManager = StateObject(wrappedValue: BackgroundImageManager(userId: userId))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                MainAccentGradient()

                // 編集エリア
                editingArea

                // コントロールボタン（固定位置）
                VStack {
                    Spacer()
                    controlButtons
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        saveImageConfiguration()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(backgroundImageManager.isSaving || selectedImage == nil)
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(selectedImage: $selectedImage)
        }
        .onAppear {
            print("📱 CardBackgroundEditView.onAppear - isLoading: \(backgroundImageManager.isLoading)")
            // 読み込み中の場合は待機、完了済みの場合は即座に復元
            if !backgroundImageManager.isLoading {
                restoreEditingState()
            }
        }
        .onChange(of: backgroundImageManager.isLoading) { isLoading in
            print("🔄 BackgroundImageManager.isLoading changed: \(isLoading)")
            // 読み込み完了時に復元処理を実行
            if !isLoading {
                print("✅ 読み込み完了 - 編集状態復元を実行")
                restoreEditingState()
            }
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                backgroundImageManager.setOriginalImage(image)
            }
        }
    }

    private var editingArea: some View {
        GeometryReader { geometry in
            ZStack {
                // 画像があるときだけ背景画像を表示
                if let image = selectedImage {
                    ZStack {
                        // 背景色（カード範囲のみ）
                        if selectedBackgroundColor != Color.clear {
                            selectedBackgroundColor
                                .mask(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.black)
                                        .frame(width: cardSize.width, height: cardSize.height)
                                )
                        }

                        // 背景画像（透過）
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(image.size, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(0.5)
                            .offset(imageOffset)
                            .scaleEffect(imageScale)

                        // 背景画像（カード範囲のみ不透明）
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(image.size, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(1.0)
                            .offset(imageOffset)
                            .scaleEffect(imageScale)
                            .mask(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black)
                                    .frame(width: cardSize.width, height: cardSize.height)
                            )
                    }
                    .gesture(
                        SimultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    imageOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = imageOffset
                                },
                            MagnificationGesture()
                                .onChanged { value in
                                    imageScale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = imageScale
                                }
                        )
                    )
                }

                // 背景色のみの場合のプレビュー
                if selectedImage == nil && selectedBackgroundColor != Color.clear {
                    selectedBackgroundColor
                        .mask(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black)
                                .frame(width: cardSize.width, height: cardSize.height)
                        )
                }

                // 画像の有無に関わらずカードを中央に表示
                VStack {
                    Spacer()
                    UserHeartbeatCard(
                        customBackgroundImage: nil,
                        displayName: "プレビュー",
                        displayBPM: "72"
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

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

            ZStack {
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

                ColorPicker("", selection: $selectedBackgroundColor)
                    .labelsHidden()
                    .scaleEffect(CGSize(width: 2, height: 2))
                    .opacity(0.011)
                    .allowsHitTesting(true)
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
                .opacity(selectedImage != nil ? 1.0 : 0.5)
            }
            .disabled(selectedImage == nil)
        }
    }

    private var isImageInCardBounds: Bool {
        // 画像がカード範囲内にあるかを簡易判定
        let imageCenter = CGPoint(
            x: cardFrame.midX + imageOffset.width,
            y: cardFrame.midY + imageOffset.height
        )

        return cardFrame.contains(imageCenter)
    }

    private func resetImagePosition() {
        withAnimation(.spring()) {
            imageOffset = .zero
            lastOffset = .zero
            imageScale = 1.0
            lastScale = 1.0
        }
    }

    private func restoreEditingState() {
        print("🔄 restoreEditingState開始 - userId: \(userId)")
        print("📋 BackgroundImageManager状態確認:")
        print("   - currentOriginalImage: \(backgroundImageManager.currentOriginalImage != nil ? "あり(\(backgroundImageManager.currentOriginalImage!.size))" : "なし")")
        print("   - currentTransform.scale: \(backgroundImageManager.currentTransform.scale)")
        print("   - currentTransform.offset: \(backgroundImageManager.currentTransform.normalizedOffset)")
        print("   - currentTransform.backgroundColor: \(backgroundImageManager.currentTransform.backgroundColor?.description ?? "なし")")
        
        // 既存の元画像を復元
        if let originalImage = backgroundImageManager.currentOriginalImage {
            selectedImage = originalImage
            print("🖼️ 元画像復元: \(originalImage.size)")
            
            // 位置とスケールを復元
            let screenSize = UIScreen.main.bounds.size
            print("📱 画面サイズ: \(screenSize)")
            
            let restoredOffsetX = backgroundImageManager.currentTransform.normalizedOffset.x * screenSize.width
            let restoredOffsetY = backgroundImageManager.currentTransform.normalizedOffset.y * screenSize.height
            
            imageOffset = CGSize(width: restoredOffsetX, height: restoredOffsetY)
            lastOffset = imageOffset
            imageScale = backgroundImageManager.currentTransform.scale
            lastScale = imageScale
            
            print("📐 位置・スケール復元:")
            print("   - 正規化オフセット: \(backgroundImageManager.currentTransform.normalizedOffset)")
            print("   - 復元オフセット: \(imageOffset)")
            print("   - 復元スケール: \(imageScale)")
        } else {
            print("❌ 元画像なし - 新規編集モード")
        }
        
        // 背景色を復元
        if let backgroundColor = backgroundImageManager.currentTransform.backgroundColor {
            selectedBackgroundColor = Color(backgroundColor)
            print("🎨 背景色復元: \(backgroundColor)")
        } else {
            selectedBackgroundColor = Color.clear
            print("🎨 背景色: クリア(デフォルト)")
        }
        
        print("✅ 編集状態復元完了:")
        print("   - 画像: \(selectedImage != nil ? "復元済み" : "なし")")
        print("   - 位置: \(imageOffset)")
        print("   - スケール: \(imageScale)")
        print("   - 背景色: \(selectedBackgroundColor)")
    }

    private func saveImageConfiguration() {
        // 正規化座標系でのTransformを作成（背景色も含む）
        let screenSize = UIScreen.main.bounds.size
        let normalizedOffsetX = imageOffset.width / screenSize.width
        let normalizedOffsetY = imageOffset.height / screenSize.height

        // 背景色をUIColorに変換（Color.clearの場合はnilに）
        let bgColor: UIColor? =
            selectedBackgroundColor == Color.clear ? nil : UIColor(selectedBackgroundColor)

        print(
            "保存時の画像オフセット: \(imageOffset), スケール: \(imageScale), 背景色: \(bgColor?.description ?? "nil")"
        )
        let transform = ImageTransform(
            scale: imageScale,
            normalizedOffset: CGPoint(x: normalizedOffsetX, y: normalizedOffsetY),
            backgroundColor: bgColor
        )

        // BackgroundImageManagerの新しいメソッドを使用して選択画像と編集状態を保存
        backgroundImageManager.saveEditingState(selectedImage: selectedImage, transform: transform)
        print("画像設定を保存: 選択画像=\(selectedImage != nil), transform=\(transform), backgroundColor=\(bgColor?.description ?? "nil")")
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    CardBackgroundEditView(userId: "preview-user")
}

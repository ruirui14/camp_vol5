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
            // 画像は表示せず、編集画面から写真選択を行う方針に変更
            // 既存の変換情報のみ復元
            if backgroundImageManager.currentOriginalImage != nil {
                let screenSize = UIScreen.main.bounds.size
                imageOffset = CGSize(
                    width: backgroundImageManager.currentTransform.normalizedOffset.x
                        * screenSize.width,
                    height: backgroundImageManager.currentTransform.normalizedOffset.y
                        * screenSize.height
                )
                lastOffset = imageOffset
                imageScale = backgroundImageManager.currentTransform.scale
                lastScale = imageScale
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

    private func saveImageConfiguration() {
        guard selectedImage != nil else {
            print("保存する画像がありません")
            return
        }
        // 正規化座標系でのTransformを作成
        let screenSize = UIScreen.main.bounds.size
        let normalizedOffsetX = imageOffset.width / screenSize.width
        let normalizedOffsetY = imageOffset.height / screenSize.height
        let transform = ImageTransform(
            scale: imageScale,
            normalizedOffset: CGPoint(x: normalizedOffsetX, y: normalizedOffsetY)
        )
        // BackgroundImageManagerを使用して保存
        backgroundImageManager.saveEditedResult(transform)
        print("画像設定を保存: transform=\(transform)")
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

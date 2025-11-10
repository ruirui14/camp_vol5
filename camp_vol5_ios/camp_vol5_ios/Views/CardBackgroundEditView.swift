// CardBackgroundEditView.swift
// カード背景画像編集ビュー - MVVM設計
// 責務: カード背景画像の選択、配置、色指定のUIを提供

import PhotosUI
import SwiftUI

struct CardBackgroundEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: CardBackgroundEditViewModel
    @State private var transformableView: TransformableCardImageView?
    @State private var currentImage: UIImage?

    let userId: String

    init(userId: String) {
        self.userId = userId
        self._viewModel = StateObject(
            wrappedValue: CardBackgroundEditViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
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
                        completeAndSave()
                        // 保存処理完了を待ってから画面を閉じる
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    }
                    .foregroundColor(.white)
                    .disabled(viewModel.isSaving || currentImage == nil)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingPhotoPicker) {
            PhotoPicker(selectedImage: $viewModel.selectedImage)
        }
        .onAppear {
            viewModel.onAppear()
            currentImage = viewModel.selectedImage
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            viewModel.onLoadingChanged(isLoading: isLoading)
            if !isLoading {
                currentImage = viewModel.selectedImage
            }
        }
        .onChange(of: viewModel.selectedImage) { _, newImage in
            viewModel.onSelectedImageChanged(newImage: newImage)
            currentImage = newImage
        }
    }

    private var editingArea: some View {
        GeometryReader { geometry in
            let cardWidth = CardConstants.cardWidth(for: geometry.size.width)
            let cardSize = CGSize(width: cardWidth, height: CardConstants.cardHeight)

            ZStack {
                // 背景色（カード範囲のみ）
                if viewModel.selectedBackgroundColor != Color.clear {
                    viewModel.selectedBackgroundColor
                        .mask(
                            RoundedRectangle(cornerRadius: CardConstants.cornerRadius)
                                .fill(Color.black)
                                .frame(width: cardWidth, height: CardConstants.cardHeight)
                        )
                }

                // 画像があるときはTransformableCardImageViewを使用
                if let image = currentImage {
                    let view = TransformableCardImageView(
                        image: image,
                        cardSize: cardSize,
                        transformState: viewModel.transformState
                    )
                    view
                        .onAppear {
                            transformableView = view
                        }
                }

                // 画像の有無に関わらずカードを中央に表示
                VStack {
                    Spacer()
                    UserHeartbeatCard(
                        customBackgroundImage: nil,
                        displayName: "プレビュー",
                        displayBPM: "72"
                    )
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var controlButtons: some View {
        HStack(alignment: .top, spacing: 20) {
            Button(
                action: {
                    viewModel.showingPhotoPicker = true
                },
                label: {
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
                }
            )
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

                ColorPicker("", selection: $viewModel.selectedBackgroundColor)
                    .labelsHidden()
                    .scaleEffect(CGSize(width: 2, height: 2))
                    .opacity(0.011)
                    .allowsHitTesting(true)
            }

            Button(action: viewModel.resetImagePosition) {
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
                .opacity(currentImage != nil ? 1.0 : 0.5)
            }
            .disabled(currentImage == nil)
        }
    }

    /// 完了ボタンの処理：画像をキャプチャして永続化
    private func completeAndSave() {
        guard
            let capturedImage = transformableView?.captureImage(
                backgroundColor: viewModel.selectedBackgroundColor,
                sourceImage: currentImage
            )
        else {
            return
        }

        viewModel.saveCapturedImageDirectly(capturedImage)
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

    func updateUIViewController(_: PHPickerViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
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

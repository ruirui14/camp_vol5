// CardBackgroundEditView.swift
// UserHeartbeatCardの背景画像を編集するビュー
// 透過画像をドラッグ・ズームで配置し、カード範囲内では透過を解除

import PhotosUI
import SwiftUI

struct CardBackgroundEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var showingPhotoPicker = false
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var imageScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var cardFrame: CGRect = .zero

    // UserHeartbeatCardと同じサイズ
    private let cardSize = CGSize(width: 370, height: 120)

    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    gradient: Gradient(colors: [.main, .accent]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // 編集エリア
                    editingArea

                    // コントロールボタン
                    controlButtons
                }
                .padding()
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
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(selectedImage: $selectedImage)
        }
        .interactiveDismissDisabled()
    }

    private var editingArea: some View {
        ZStack {
            // 編集中の画像（全体表示）
            if let image = selectedImage {
                ZStack {
                    // 透過された背景画像（全体）
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height
                        )
                        .clipped()
                        .opacity(0.5)
                        .offset(imageOffset)
                        .scaleEffect(imageScale)

                    // カード範囲内のみ透過を解除した画像
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height
                        )
                        .clipped()
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
                            .onEnded { value in
                                lastOffset = imageOffset
                            },
                        MagnificationGesture()
                            .onChanged { value in
                                imageScale = lastScale * value
                            }
                            .onEnded { value in
                                lastScale = imageScale
                            }
                    )
                )
            }

            // 中央にUserHeartbeatCardのプレビュー
            UserHeartbeatCard(
                customBackgroundImage: nil,
                displayName: "プレビュー",
                displayBPM: "72"
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var controlButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingPhotoPicker = true
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("写真を選択")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }

            if selectedImage != nil {
                Button(action: resetImagePosition) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("位置をリセット")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
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
        // TODO: 画像の設定を保存
        // BackgroundImageManagerを使用して保存処理を実装
        print("画像設定を保存: offset=\(imageOffset), scale=\(imageScale)")
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
    CardBackgroundEditView()
}

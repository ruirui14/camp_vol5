// Views/Components/GifPhotoPickerView.swift
// GIF対応のフォトピッカー - PHPickerViewControllerをラップ
// 通常の画像とGIFアニメーションの両方を選択可能

import PhotosUI
import SwiftUI

/// GIFアニメーション対応のフォトピッカー
struct GifPhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: PHPickerViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: GifPhotoPickerView

        init(_ parent: GifPhotoPickerView) {
            self.parent = parent
        }

        func picker(_: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            // GIFデータを優先的に読み込み
            if provider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.gif.identifier) {
                    data, error in
                    if let error = error {
                        print("Error loading GIF: \(error)")
                        return
                    }

                    guard let data = data else { return }

                    DispatchQueue.main.async {
                        self.parent.selectedImageData = data
                        // GIFデータからUIImageを作成（アニメーション情報を保持）
                        if let image = UIImage(data: data) {
                            self.parent.selectedImage = image
                        }
                    }
                }
            } else if provider.canLoadObject(ofClass: UIImage.self) {
                // 通常の画像として読み込み
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }

                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                        self.parent.selectedImageData = nil
                    }
                }
            }
        }
    }
}

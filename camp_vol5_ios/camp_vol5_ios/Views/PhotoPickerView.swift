//
//  PhotoPickerView.swift
//  camp_vol5_ios
//
//  シンプルな写真選択ビュー
//

// import PhotosUI
// import SwiftUI

// struct SimplePhotoPickerView: UIViewControllerRepresentable {
//     @Binding var selectedImage: UIImage?
//     let onImageSelected: () -> Void
//     @Environment(\.presentationMode) var presentationMode

//     func makeUIViewController(context: Context) -> PHPickerViewController {
//         var configuration = PHPickerConfiguration()
//         configuration.filter = .images
//         configuration.selectionLimit = 1

//         let picker = PHPickerViewController(configuration: configuration)
//         picker.delegate = context.coordinator
//         return picker
//     }

//     func updateUIViewController(_: PHPickerViewController, context _: Context) {}

//     func makeCoordinator() -> Coordinator {
//         Coordinator(self)
//     }

//     class Coordinator: NSObject, PHPickerViewControllerDelegate {
//         var parent: SimplePhotoPickerView

//         init(_ parent: SimplePhotoPickerView) {
//             self.parent = parent
//         }

//         func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//             picker.dismiss(animated: true)

//             guard let result = results.first else {
//                 return
//             }

//             result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
//                 if let image = image as? UIImage {
//                     DispatchQueue.main.async {
//                         self.parent.selectedImage = image
//                         self.parent.onImageSelected()
//                     }
//                 }
//             }
//         }
//     }
// }

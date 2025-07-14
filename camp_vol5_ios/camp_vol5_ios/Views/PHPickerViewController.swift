import SwiftUI
import PhotosUI

// PHPickerViewControllerのSwiftUIラッパー
struct PHPickerViewControllerWrapper: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // 更新処理は不要
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerViewControllerWrapper
        
        init(_ parent: PHPickerViewControllerWrapper) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard let provider = results.first?.itemProvider else { 
                print("No provider found")
                return 
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            print("Image loaded successfully")
                            self.parent.onImageSelected(image)
                        } else {
                            print("Failed to cast to UIImage")
                        }
                    }
                }
            } else {
                print("Cannot load UIImage")
            }
        }
    }
}
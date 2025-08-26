// ViewModels/CardBackgroundEditViewModel.swift
// CardBackgroundEditViewのViewModel
// 画像の編集状態とBackgroundImageManagerの状態を管理

import Combine
import SwiftUI

class CardBackgroundEditViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var showingPhotoPicker = false
    @Published var imageOffset: CGSize = .zero
    @Published var imageScale: CGFloat = 1.0
    @Published var selectedBackgroundColor: Color = .clear
    @Published var isLoading = false
    @Published var isSaving = false

    private var lastOffset: CGSize = .zero
    private var lastScale: CGFloat = 1.0
    private let backgroundImageManager: BackgroundImageManager
    private var cancellables = Set<AnyCancellable>()

    init(userId: String, authenticationManager: AuthenticationManager) {
        self.backgroundImageManager = BackgroundImageManager(userId: userId)

        // BackgroundImageManagerの状態を監視
        backgroundImageManager.$isLoading
            .assign(to: &$isLoading)

        backgroundImageManager.$isSaving
            .assign(to: &$isSaving)

        // 初期化時の状態復元はViewDidAppearで行う
    }

    func onAppear() {
        if !isLoading {
            restoreEditingState()
        }
    }

    func onLoadingChanged(isLoading: Bool) {
        if !isLoading {
            restoreEditingState()
        }
    }

    func onSelectedImageChanged(newImage: UIImage?) {
        if let image = newImage {
            backgroundImageManager.setOriginalImage(image)
        }
    }

    func updateImageOffset(translation: CGSize) {
        imageOffset = CGSize(
            width: lastOffset.width + translation.width,
            height: lastOffset.height + translation.height
        )
    }

    func finalizeImageOffset() {
        lastOffset = imageOffset
    }

    func updateImageScale(magnification: CGFloat) {
        imageScale = lastScale * magnification
    }

    func finalizeImageScale() {
        lastScale = imageScale
    }

    func resetImagePosition() {
        withAnimation(.spring()) {
            imageOffset = .zero
            lastOffset = .zero
            imageScale = 1.0
            lastScale = 1.0
        }
    }

    func saveImageConfiguration() {
        let screenSize = UIScreen.main.bounds.size
        let normalizedOffsetX = imageOffset.width / screenSize.width
        let normalizedOffsetY = imageOffset.height / screenSize.height

        let bgColor: UIColor? =
            selectedBackgroundColor == Color.clear ? nil : UIColor(selectedBackgroundColor)

        let transform = ImageTransform(
            scale: imageScale,
            normalizedOffset: CGPoint(x: normalizedOffsetX, y: normalizedOffsetY),
            backgroundColor: bgColor
        )

        backgroundImageManager.saveEditingState(selectedImage: selectedImage, transform: transform)
    }

    private func restoreEditingState() {
        if let originalImage = backgroundImageManager.currentOriginalImage {
            selectedImage = originalImage

            let screenSize = UIScreen.main.bounds.size
            let restoredOffsetX =
                backgroundImageManager.currentTransform.normalizedOffset.x * screenSize.width
            let restoredOffsetY =
                backgroundImageManager.currentTransform.normalizedOffset.y * screenSize.height

            imageOffset = CGSize(width: restoredOffsetX, height: restoredOffsetY)
            lastOffset = imageOffset
            imageScale = backgroundImageManager.currentTransform.scale
            lastScale = imageScale
        }

        if let backgroundColor = backgroundImageManager.currentTransform.backgroundColor {
            selectedBackgroundColor = Color(backgroundColor)
        } else {
            selectedBackgroundColor = Color.clear
        }
    }
}

// Services/BackgroundImageManager.swift
// 背景画像管理サービス

import SwiftUI
import UIKit

// MARK: - 背景画像管理マネージャー

class BackgroundImageManager: ObservableObject {
    @Published var currentEditedImage: UIImage?
    @Published var currentThumbnail: UIImage?
    @Published var currentOriginalImage: UIImage?
    @Published var currentTransform: ImageTransform = .init()
    @Published var isLoading = false
    @Published var isSaving = false

    private let userId: String
    private let persistenceManager = EnhancedImagePersistenceManager.shared
    private let userDefaultsManager = EnhancedUserDefaultsManager.shared

    init(userId: String) {
        self.userId = userId
        loadPersistedImages()
    }

    private func loadPersistedImages() {
        isLoading = true

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            if let savedData = self.userDefaultsManager.loadBackgroundImageData(for: self.userId) {
                let editedImage = self.persistenceManager.loadImage(
                    fileName: savedData.editedImageFileName
                )
                let thumbnail = self.persistenceManager.loadImage(
                    fileName: savedData.thumbnailFileName
                )
                let originalImage = self.persistenceManager.loadImage(
                    fileName: savedData.originalImageFileName
                )

                DispatchQueue.main.async {
                    self.currentEditedImage = editedImage
                    self.currentThumbnail = thumbnail
                    self.currentOriginalImage = originalImage
                    self.currentTransform = savedData.transform
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }

    func setOriginalImage(_ image: UIImage) {
        let screenSize = UIScreen.main.bounds.size
        let maxSize = CGSize(width: screenSize.width * 2, height: screenSize.height * 2)

        guard let processedImage = image.downsample(to: maxSize) else {
            return
        }

        currentOriginalImage = processedImage
        currentTransform = ImageTransform()
    }

    func saveEditedResult(_ transform: ImageTransform) {
        guard let originalImage = currentOriginalImage else {
            return
        }

        isSaving = true
        currentTransform = transform

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            let screenSize = UIScreen.main.bounds.size

            guard
                let persistentData = self.persistenceManager.saveEditedImageSet(
                    originalImage: originalImage,
                    transform: transform,
                    userId: self.userId,
                    targetScreenSize: screenSize
                )
            else {
                DispatchQueue.main.async {
                    self.isSaving = false
                }
                return
            }

            self.userDefaultsManager.saveBackgroundImageData(persistentData)

            let editedImage = self.persistenceManager.loadImage(
                fileName: persistentData.editedImageFileName
            )
            let thumbnail = self.persistenceManager.loadImage(
                fileName: persistentData.thumbnailFileName
            )

            DispatchQueue.main.async {
                self.currentEditedImage = editedImage
                self.currentThumbnail = thumbnail
                self.isSaving = false
            }
        }
    }

    func saveEditingState(selectedImage: UIImage?, transform: ImageTransform) {
        // 新しく選択された画像がある場合は元画像として設定
        if let newImage = selectedImage {
            setOriginalImage(newImage)
        }

        // 編集中の変換情報を保存
        currentTransform = transform

        // 元画像がある場合のみ完全な保存処理を実行
        if currentOriginalImage != nil {
            saveEditedResult(transform)
        }
    }

    func resetBackgroundImage() {
        if let savedData = userDefaultsManager.loadBackgroundImageData(for: userId) {
            persistenceManager.deleteImageSet(savedData)
        }
        userDefaultsManager.deleteBackgroundImageData(for: userId)

        currentEditedImage = nil
        currentThumbnail = nil
        currentOriginalImage = nil
        currentTransform = ImageTransform()
    }

    func getOriginalImageForReEdit() -> UIImage? {
        return currentOriginalImage
    }

    func getFinalDisplayImage() -> UIImage? {
        return currentEditedImage
    }

    func getThumbnailImage() -> UIImage? {
        return currentThumbnail
    }

    func refreshFromStorage() {
        loadPersistedImages()
    }
}

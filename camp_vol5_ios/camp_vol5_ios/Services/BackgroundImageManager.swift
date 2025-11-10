// Services/BackgroundImageManager.swift
// 背景画像管理サービス - MVVM設計のModel層
// 責務: ユーザーごとの背景画像の読み込み・保存・削除を管理

import SwiftUI
import UIKit

/// 背景画像管理マネージャー
/// - ユーザーIDごとに背景画像（オリジナル/編集済み）と変形情報を管理
/// - ImagePersistenceServiceとUserDefaultsImageServiceを組み合わせて永続化
/// - ObservableObjectとして状態変化をViewに通知
class BackgroundImageManager: ObservableObject {
    /// 現在の編集済み画像
    @Published var currentEditedImage: UIImage?

    /// 現在のオリジナル画像
    @Published var currentOriginalImage: UIImage?

    /// 現在の変形情報
    @Published var currentTransform: ImageTransform = .init()

    /// 画像読み込み中フラグ
    @Published var isLoading = false

    /// 画像保存中フラグ
    @Published var isSaving = false

    private let userId: String
    private let persistenceService = ImagePersistenceService.shared
    private let userDefaultsService = UserDefaultsImageService.shared

    var userIdForDebugging: String {
        userId
    }

    init(userId: String) {
        self.userId = userId
        loadPersistedImages()
    }

    private func loadPersistedImages() {
        isLoading = true

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            if let savedData = self.userDefaultsService.loadBackgroundImageData(for: self.userId) {
                let editedImage = self.persistenceService.loadImage(
                    fileName: savedData.editedImageFileName
                )
                let originalImage = self.persistenceService.loadImage(
                    fileName: savedData.originalImageFileName
                )

                DispatchQueue.main.async {
                    self.currentEditedImage = editedImage
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

    /// オリジナル画像を設定（ダウンサンプリング処理を含む）
    /// - Parameter image: 設定する画像
    func setOriginalImage(_ image: UIImage) {
        let screenSize = UIScreen.main.bounds.size
        let maxSize = CGSize(width: screenSize.width * 2, height: screenSize.height * 2)

        Task {
            guard let processedImage = await image.downsample(to: maxSize) else {
                return
            }

            await MainActor.run {
                currentOriginalImage = processedImage
                currentTransform = ImageTransform()
            }
        }
    }

    /// 編集結果を保存（フルサイズ画像生成を含む）
    /// - Parameter transform: 変形情報
    func saveEditedResult(_ transform: ImageTransform) {
        guard let originalImage = currentOriginalImage else {
            return
        }

        isSaving = true
        currentTransform = transform

        Task {
            let screenSize = UIScreen.main.bounds.size

            guard
                let persistentData = await self.persistenceService.saveEditedImageSet(
                    originalImage: originalImage,
                    transform: transform,
                    userId: self.userId,
                    targetScreenSize: screenSize
                )
            else {
                await MainActor.run {
                    self.isSaving = false
                }
                return
            }

            self.userDefaultsService.saveBackgroundImageData(persistentData)

            let editedImage = self.persistenceService.loadImage(
                fileName: persistentData.editedImageFileName
            )

            await MainActor.run {
                self.currentEditedImage = editedImage
                self.isSaving = false
            }
        }
    }

    /// 編集状態を保存（画像と変形情報）
    /// - Parameters:
    ///   - selectedImage: 選択された画像
    ///   - transform: 変形情報
    func saveEditingState(selectedImage: UIImage?, transform: ImageTransform) {
        if let newImage = selectedImage {
            setOriginalImage(newImage)
        }

        currentTransform = transform

        if currentOriginalImage != nil {
            saveEditedResult(transform)
        }
    }

    /// 背景画像をリセット（ファイルとメタデータを削除）
    func resetBackgroundImage() {
        if let savedData = userDefaultsService.loadBackgroundImageData(for: userId) {
            persistenceService.deleteImageSet(savedData)
        }
        userDefaultsService.deleteBackgroundImageData(for: userId)

        currentEditedImage = nil
        currentOriginalImage = nil
        currentTransform = ImageTransform()
    }

    /// ストレージから画像を再読み込み
    func refreshFromStorage() {
        loadPersistedImages()
    }
}

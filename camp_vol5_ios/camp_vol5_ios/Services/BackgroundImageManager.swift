// Services/BackgroundImageManager.swift
// 背景画像管理サービス - MVVM設計のModel層
// 責務: ユーザーごとの背景画像の読み込み・保存・削除を管理

import SwiftUI
import UIKit

/// 背景画像管理マネージャー（カード背景用、GIF対応）
/// - ユーザーIDごとに背景画像（オリジナル/編集済み）と変形情報を管理
/// - ImagePersistenceServiceとUserDefaultsImageServiceを組み合わせて永続化
/// - GIFアニメーション画像のデータとフラグも管理
/// - ObservableObjectとして状態変化をViewに通知
/// - 注意：詳細画面の背景はPersistenceManagerで管理されており、こちらとは別システム
class BackgroundImageManager: ObservableObject {
    /// 現在の編集済み画像
    @Published var currentEditedImage: UIImage?

    /// 現在のオリジナル画像
    @Published var currentOriginalImage: UIImage?

    /// 現在の画像データ（GIF対応）
    @Published var currentImageData: Data?

    /// アニメーション画像かどうか
    @Published var isAnimated: Bool = false

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

                // GIFデータを読み込み（アニメーション画像の場合）
                var imageData: Data?
                if savedData.isAnimated {
                    imageData = self.persistenceService.loadImageData(
                        fileName: savedData.originalImageFileName
                    )
                }

                DispatchQueue.main.async {
                    self.currentEditedImage = editedImage
                    self.currentOriginalImage = originalImage
                    self.currentImageData = imageData
                    self.isAnimated = savedData.isAnimated
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

    /// 背景画像をリセット（ファイルとメタデータを削除）
    func resetBackgroundImage() {
        if let savedData = userDefaultsService.loadBackgroundImageData(for: userId) {
            persistenceService.deleteImageSet(savedData)
        }
        userDefaultsService.deleteBackgroundImageData(for: userId)

        currentEditedImage = nil
        currentOriginalImage = nil
        currentImageData = nil
        isAnimated = false
        currentTransform = ImageTransform()
    }

    /// ストレージから画像を再読み込み
    func refreshFromStorage() {
        loadPersistedImages()
    }
}

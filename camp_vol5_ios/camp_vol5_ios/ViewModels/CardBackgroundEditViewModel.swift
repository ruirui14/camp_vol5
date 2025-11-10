// ViewModels/CardBackgroundEditViewModel.swift
// CardBackgroundEditViewのViewModel - MVVM設計
// 責務: 画像編集のUI状態管理とBackgroundImageManagerとの連携

import Combine
import SwiftUI

class CardBackgroundEditViewModel: NSObject, ObservableObject {
    /// 選択された画像（編集前のオリジナル）
    @Published var selectedImage: UIImage?

    /// 写真ピッカーの表示状態
    @Published var showingPhotoPicker = false

    /// 画像の変形状態（拡大、移動、回転）
    @Published var transformState = CardImageTransformState()

    /// 選択された背景色
    @Published var selectedBackgroundColor: Color = .clear

    /// 画像読み込み中フラグ
    @Published var isLoading = false

    /// 画像保存中フラグ
    @Published var isSaving = false

    private let backgroundImageManager: BackgroundImageManager
    private var cancellables = Set<AnyCancellable>()

    init(userId: String) {
        self.backgroundImageManager = BackgroundImageManager(userId: userId)
        super.init()
        setupObservers()
    }

    private func setupObservers() {
        backgroundImageManager.$isLoading
            .assign(to: &$isLoading)

        backgroundImageManager.$isSaving
            .assign(to: &$isSaving)
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

    func resetImagePosition() {
        withAnimation(.spring()) {
            transformState.reset()
        }
    }

    /// キャプチャした画像を永続化
    /// - Parameter capturedImage: TransformableCardImageViewでキャプチャした編集済み画像
    func saveCapturedImageDirectly(_ capturedImage: UIImage) {
        let userDefaultsService = UserDefaultsImageService.shared
        let existingData = userDefaultsService.loadBackgroundImageData(
            for: backgroundImageManager.userIdForDebugging)

        // ファイル名の決定（既存を再利用、なければ新規作成）
        let (editedFileName, originalFileName) = determineFileNames(existingData: existingData)

        // 編集済み画像を保存
        guard saveEditedImage(capturedImage, fileName: editedFileName) else {
            return
        }

        // オリジナル画像を保存（初回のみ）
        if existingData == nil {
            saveOriginalImage(fileName: originalFileName)
        }

        print("🔥 originalFileName: \(originalFileName)")
        print("🔥 editedFileName: \(editedFileName)")

        // 変形状態のメタデータを作成・保存
        let transform = createTransform()
        let persistentData = createPersistentData(
            originalFileName: originalFileName,
            editedFileName: editedFileName,
            transform: transform,
            imageSize: capturedImage.size
        )

        userDefaultsService.saveBackgroundImageData(persistentData)

        // BackgroundImageManagerの状態を同期
        updateBackgroundImageManagerState(
            editedImage: capturedImage,
            transform: transform
        )
    }

    /// ファイル名を決定（既存を再利用または新規作成）
    private func determineFileNames(
        existingData: EnhancedPersistentImageData?
    ) -> (editedFileName: String, originalFileName: String) {
        if let existing = existingData {
            return (existing.editedImageFileName, existing.originalImageFileName)
        } else {
            let timestamp = UUID().uuidString
            let userId = backgroundImageManager.userIdForDebugging
            return (
                editedFileName: "\(userId)_edited_\(timestamp).png",
                originalFileName: "\(userId)_original_\(timestamp).png"
            )
        }
    }

    /// 編集済み画像をファイルに保存
    private func saveEditedImage(_ image: UIImage, fileName: String) -> Bool {
        FileManager.ensureBackgroundImagesDirectory()
        let fileURL = FileManager.backgroundImagesDirectory.appendingPathComponent(fileName)

        guard let imageData = image.pngData() else {
            return false
        }

        do {
            try imageData.write(to: fileURL)
            return true
        } catch {
            return false
        }
    }

    /// オリジナル画像をファイルに保存
    private func saveOriginalImage(fileName: String) {
        guard let originalImage = selectedImage else { return }

        let fileURL = FileManager.backgroundImagesDirectory.appendingPathComponent(fileName)
        if let imageData = originalImage.pngData() {
            try? imageData.write(to: fileURL)
        }
    }

    /// 現在の変形状態からImageTransformを作成
    private func createTransform() -> ImageTransform {
        let screenSize = UIScreen.main.bounds.size
        let normalizedOffset = CGPoint(
            x: transformState.currentOffset.width / screenSize.width,
            y: transformState.currentOffset.height / screenSize.height
        )

        let backgroundColor: UIColor? =
            selectedBackgroundColor == .clear ? nil : UIColor(selectedBackgroundColor)

        return ImageTransform(
            scale: transformState.currentScale,
            normalizedOffset: normalizedOffset,
            rotation: transformState.currentAngle.degrees,
            backgroundColor: backgroundColor
        )
    }

    /// 永続化データを作成
    private func createPersistentData(
        originalFileName: String,
        editedFileName: String,
        transform: ImageTransform,
        imageSize: CGSize
    ) -> EnhancedPersistentImageData {
        return EnhancedPersistentImageData(
            originalImageFileName: originalFileName,
            editedImageFileName: editedFileName,
            transform: transform,
            createdAt: Date(),
            userId: backgroundImageManager.userIdForDebugging,
            imageSize: imageSize
        )
    }

    /// BackgroundImageManagerの状態を更新
    private func updateBackgroundImageManagerState(
        editedImage: UIImage,
        transform: ImageTransform
    ) {
        backgroundImageManager.currentEditedImage = editedImage
        backgroundImageManager.currentOriginalImage = selectedImage
        backgroundImageManager.currentTransform = transform
    }

    /// 前回の編集状態を復元
    /// - BackgroundImageManagerから画像と変形情報を読み込む
    private func restoreEditingState() {
        restoreImage()
        restoreTransform()
        restoreBackgroundColor()
    }

    /// 画像を復元
    private func restoreImage() {
        selectedImage = backgroundImageManager.currentOriginalImage
    }

    /// 変形状態を復元
    private func restoreTransform() {
        let transform = backgroundImageManager.currentTransform
        let screenSize = UIScreen.main.bounds.size

        // 正規化されたオフセットを実際のサイズに変換
        let restoredOffset = CGSize(
            width: transform.normalizedOffset.x * screenSize.width,
            height: transform.normalizedOffset.y * screenSize.height
        )

        transformState.currentOffset = restoredOffset
        transformState.currentScale = transform.scale
        transformState.currentAngle = Angle(degrees: transform.rotation)
    }

    /// 背景色を復元
    private func restoreBackgroundColor() {
        if let backgroundColor = backgroundImageManager.currentTransform.backgroundColor {
            selectedBackgroundColor = Color(backgroundColor)
        } else {
            selectedBackgroundColor = .clear
        }
    }
}

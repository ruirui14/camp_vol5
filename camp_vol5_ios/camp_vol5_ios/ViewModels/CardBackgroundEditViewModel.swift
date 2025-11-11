// ViewModels/CardBackgroundEditViewModel.swift
// CardBackgroundEditViewのViewModel - MVVM設計
// 責務: 画像編集のUI状態管理とBackgroundImageManagerとの連携

import Combine
import SwiftUI

class CardBackgroundEditViewModel: NSObject, ObservableObject {
    /// 選択された画像（編集前のオリジナル）
    @Published var selectedImage: UIImage?

    /// 選択された画像データ（GIF対応）
    @Published var selectedImageData: Data?

    /// アニメーション画像かどうか
    @Published var isAnimated: Bool = false

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

    /// 新しい画像が選択されたかどうかのフラグ
    private var isNewImageSelected = false

    /// 画像復元中フラグ（復元時は新しい画像選択としてカウントしない）
    private var isRestoringState = false

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

            // 復元中でない場合のみ、新しい画像が選択されたとマーク
            if !isRestoringState {
                isNewImageSelected = true
            }
        }
    }

    func resetImagePosition() {
        withAnimation(.spring()) {
            transformState.reset()
        }
    }

    /// キャプチャした画像を永続化（GIF対応）
    /// - Parameter capturedImage: TransformableCardImageViewでキャプチャした編集済み画像
    func saveCapturedImageDirectly(_ capturedImage: UIImage) {
        let userDefaultsService = UserDefaultsImageService.shared
        let existingData = userDefaultsService.loadBackgroundImageData(
            for: backgroundImageManager.userIdForDebugging)

        // ファイル名の決定
        let (editedFileName, originalFileName) = determineFileNames(existingData: existingData)

        // 画像ファイルを保存
        guard saveEditedImage(capturedImage, fileName: editedFileName) else {
            return
        }
        saveOriginalImageIfNeeded(originalFileName: originalFileName, existingData: existingData)

        // メタデータを作成して保存
        let transform = createTransform()
        let persistentData = createPersistentData(
            originalFileName: originalFileName,
            editedFileName: editedFileName,
            transform: transform,
            imageSize: capturedImage.size,
            isAnimated: isAnimated
        )
        userDefaultsService.saveBackgroundImageData(persistentData)

        // BackgroundImageManagerの状態を同期
        updateBackgroundImageManagerState(
            editedImage: capturedImage,
            imageData: isAnimated ? selectedImageData : nil,
            isAnimated: isAnimated,
            transform: transform
        )

        // フラグをリセット
        isNewImageSelected = false
    }

    /// 編集済み画像を保存
    private func saveEditedImage(_ image: UIImage, fileName: String) -> Bool {
        return saveImage(image, fileName: fileName)
    }

    /// オリジナル画像を必要に応じて保存
    private func saveOriginalImageIfNeeded(
        originalFileName: String, existingData: EnhancedPersistentImageData?
    ) {
        guard isNewImageSelected || existingData == nil else { return }

        if let imageData = selectedImageData, isAnimated {
            // GIFデータを保存
            _ = saveImageData(imageData, fileName: originalFileName)
        } else if let originalImage = selectedImage {
            // 静止画を保存
            _ = saveImage(originalImage, fileName: originalFileName)
        }
    }

    // MARK: - ファイル保存

    /// ファイル名を決定（既存を再利用または新規作成）
    private func determineFileNames(
        existingData: EnhancedPersistentImageData?
    ) -> (editedFileName: String, originalFileName: String) {
        if isNewImageSelected || existingData == nil {
            // 新しい画像が選択された場合は、新しいファイル名を生成
            let timestamp = UUID().uuidString
            let userId = backgroundImageManager.userIdForDebugging
            return (
                editedFileName: "\(userId)_edited_\(timestamp).png",
                originalFileName: "\(userId)_original_\(timestamp).png"
            )
        } else {
            // 変形のみの変更の場合は既存のファイル名を再利用
            return (existingData!.editedImageFileName, existingData!.originalImageFileName)
        }
    }

    /// 画像をPNG形式で保存
    private func saveImage(_ image: UIImage, fileName: String) -> Bool {
        guard let imageData = image.pngData() else { return false }
        return saveData(imageData, fileName: fileName)
    }

    /// 画像データをファイルに保存（GIF対応）
    private func saveImageData(_ data: Data, fileName: String) -> Bool {
        return saveData(data, fileName: fileName)
    }

    /// データをファイルに保存（共通処理）
    private func saveData(_ data: Data, fileName: String) -> Bool {
        FileManager.ensureBackgroundImagesDirectory()
        let fileURL = FileManager.backgroundImagesDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return true
        } catch {
            return false
        }
    }

    // MARK: - メタデータ作成

    /// 現在の変形状態からImageTransformを作成
    /// オフセットは画面サイズで正規化して保存
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

    /// 永続化データを作成（GIF対応）
    private func createPersistentData(
        originalFileName: String,
        editedFileName: String,
        transform: ImageTransform,
        imageSize: CGSize,
        isAnimated: Bool
    ) -> EnhancedPersistentImageData {
        EnhancedPersistentImageData(
            originalImageFileName: originalFileName,
            editedImageFileName: editedFileName,
            transform: transform,
            createdAt: Date(),
            userId: backgroundImageManager.userIdForDebugging,
            imageSize: imageSize,
            isAnimated: isAnimated
        )
    }

    /// BackgroundImageManagerの状態を更新（GIF対応）
    private func updateBackgroundImageManagerState(
        editedImage: UIImage,
        imageData: Data?,
        isAnimated: Bool,
        transform: ImageTransform
    ) {
        backgroundImageManager.currentEditedImage = editedImage
        backgroundImageManager.currentOriginalImage = selectedImage
        backgroundImageManager.currentImageData = imageData
        backgroundImageManager.isAnimated = isAnimated
        backgroundImageManager.currentTransform = transform
    }

    // MARK: - 編集状態の復元

    /// 前回の編集状態を復元
    /// BackgroundImageManagerから画像、変形情報、背景色を読み込む
    private func restoreEditingState() {
        isRestoringState = true
        defer { isRestoringState = false }

        restoreImage()
        restoreTransform()
        restoreBackgroundColor()
    }

    /// 画像を復元（GIF対応）
    private func restoreImage() {
        selectedImage = backgroundImageManager.currentOriginalImage
        selectedImageData = backgroundImageManager.currentImageData
        isAnimated = backgroundImageManager.isAnimated
    }

    /// 変形状態を復元（正規化されたオフセットを画面サイズに合わせて変換）
    private func restoreTransform() {
        let transform = backgroundImageManager.currentTransform
        let screenSize = UIScreen.main.bounds.size

        transformState.currentOffset = CGSize(
            width: transform.normalizedOffset.x * screenSize.width,
            height: transform.normalizedOffset.y * screenSize.height
        )
        transformState.currentScale = transform.scale
        transformState.currentAngle = Angle(degrees: transform.rotation)
    }

    /// 背景色を復元
    private func restoreBackgroundColor() {
        selectedBackgroundColor =
            backgroundImageManager.currentTransform.backgroundColor
            .map { Color($0) } ?? .clear
    }
}

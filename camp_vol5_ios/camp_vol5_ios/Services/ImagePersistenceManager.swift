// Services/ImagePersistenceManager.swift
// 画像の永続化管理機能

import SwiftUI
import UIKit

// MARK: - 画像変換情報

struct ImageTransform: Codable {
    var scale: CGFloat = 1.0
    var normalizedOffset: CGPoint = .zero
    var rotation: Double = 0.0
    var backgroundColor: UIColor?

    enum CodingKeys: String, CodingKey {
        case scale
        case normalizedOffset
        case rotation
        case backgroundColor
    }

    init(
        scale: CGFloat = 1.0,
        normalizedOffset: CGPoint = .zero,
        rotation: Double = 0.0,
        backgroundColor: UIColor? = nil
    ) {
        self.scale = scale
        self.normalizedOffset = normalizedOffset
        self.rotation = rotation
        self.backgroundColor = backgroundColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scale = try container.decode(CGFloat.self, forKey: .scale)
        normalizedOffset = try container.decode(CGPoint.self, forKey: .normalizedOffset)
        rotation = try container.decodeIfPresent(Double.self, forKey: .rotation) ?? 0.0
        if let colorData = try container.decodeIfPresent(Data.self, forKey: .backgroundColor) {
            backgroundColor = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: UIColor.self, from: colorData)
        } else {
            backgroundColor = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scale, forKey: .scale)
        try container.encode(normalizedOffset, forKey: .normalizedOffset)
        try container.encode(rotation, forKey: .rotation)
        if let backgroundColor = backgroundColor {
            let colorData = try NSKeyedArchiver.archivedData(
                withRootObject: backgroundColor, requiringSecureCoding: false)
            try container.encode(colorData, forKey: .backgroundColor)
        }
    }
}

// MARK: - 永続化用データ構造

struct EnhancedPersistentImageData: Codable {
    let originalImageFileName: String
    let editedImageFileName: String
    let transform: ImageTransform
    let createdAt: Date
    let userId: String
    let imageSize: CGSize
}

// MARK: - 画像処理サービス

class ImageProcessingService {
    static let shared = ImageProcessingService()
    private init() {}

    /// バックグラウンドで画像編集処理を実行
    /// - Parameters:
    ///   - originalImage: 元画像
    ///   - transform: 変換情報
    ///   - outputSize: 出力サイズ
    /// - Returns: 編集済み画像（失敗時はnil）
    func createEditedImage(
        from originalImage: UIImage,
        transform: ImageTransform,
        outputSize: CGSize
    ) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            let renderer = UIGraphicsImageRenderer(size: outputSize)

            return renderer.image { context in
                let cgContext = context.cgContext

                // 背景をクリア
                cgContext.clear(CGRect(origin: .zero, size: outputSize))

                // 背景色が指定されている場合は塗りつぶす
                if let backgroundColor = transform.backgroundColor {
                    cgContext.setFillColor(backgroundColor.cgColor)
                    cgContext.fill(CGRect(origin: .zero, size: outputSize))
                }

                // 画像のアスペクト比を維持してフィット
                let imageSize = ImageProcessingService.shared.aspectFitSize(
                    originalImage.size, in: outputSize)

                // 中央配置の基準点を計算
                let centerX = outputSize.width / 2
                let centerY = outputSize.height / 2

                // 正規化されたオフセットを実際のピクセル値に変換
                let offsetX = transform.normalizedOffset.x * outputSize.width / 2
                let offsetY = transform.normalizedOffset.y * outputSize.height / 2

                // コンテキストの状態を保存
                cgContext.saveGState()

                // 回転の適用（中心点を基準に回転）
                cgContext.translateBy(x: centerX + offsetX, y: centerY + offsetY)
                cgContext.rotate(by: CGFloat(transform.rotation * .pi / 180))
                cgContext.translateBy(x: -(centerX + offsetX), y: -(centerY + offsetY))

                // 最終的な描画矩形を計算
                let drawRect = CGRect(
                    x: centerX - (imageSize.width * transform.scale) / 2 + offsetX,
                    y: centerY - (imageSize.height * transform.scale) / 2 + offsetY,
                    width: imageSize.width * transform.scale,
                    height: imageSize.height * transform.scale
                )

                originalImage.draw(in: drawRect)

                // コンテキストの状態を復元
                cgContext.restoreGState()
            }
        }.value
    }

    /// バックグラウンドでフルサイズ画像編集処理を実行
    /// - Parameters:
    ///   - originalImage: 元画像
    ///   - transform: 変換情報
    ///   - targetScreenSize: ターゲット画面サイズ（2倍に拡大される）
    /// - Returns: 高解像度編集済み画像（失敗時はnil）
    func createFullSizeEditedImage(
        from originalImage: UIImage,
        transform: ImageTransform,
        targetScreenSize: CGSize
    ) async -> UIImage? {
        let fullSize = CGSize(
            width: targetScreenSize.width * 2,
            height: targetScreenSize.height * 2
        )
        return await createEditedImage(
            from: originalImage,
            transform: transform,
            outputSize: fullSize
        )
    }

    func aspectFitSize(_ imageSize: CGSize, in containerSize: CGSize) -> CGSize {
        let scale = min(
            containerSize.width / imageSize.width,
            containerSize.height / imageSize.height
        )
        return CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
    }
}

// MARK: - 画像永続化サービス

class ImagePersistenceService {
    static let shared = ImagePersistenceService()
    private let imageProcessor: ImageProcessingService
    private let fileManager: FileManager

    private init() {
        self.imageProcessor = ImageProcessingService.shared
        self.fileManager = FileManager.default
    }

    /// バックグラウンドで画像セットの保存を実行
    /// - Parameters:
    ///   - originalImage: 元画像
    ///   - transform: 変換情報
    ///   - userId: ユーザーID
    ///   - targetScreenSize: ターゲット画面サイズ
    /// - Returns: 永続化データ（失敗時はnil）
    func saveEditedImageSet(
        originalImage: UIImage,
        transform: ImageTransform,
        userId: String,
        targetScreenSize: CGSize
    ) async -> EnhancedPersistentImageData? {
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return nil }

            FileManager.ensureBackgroundImagesDirectory()

            let timestamp = UUID().uuidString
            let originalFileName = "\(userId)_original_\(timestamp).png"
            let editedFileName = "\(userId)_edited_\(timestamp).png"

            guard self.saveImage(originalImage, fileName: originalFileName) else {
                return nil
            }

            guard
                let editedImage = await self.imageProcessor.createFullSizeEditedImage(
                    from: originalImage,
                    transform: transform,
                    targetScreenSize: targetScreenSize
                ), self.saveImage(editedImage, fileName: editedFileName)
            else {
                self.deleteImage(fileName: originalFileName)
                return nil
            }

            let persistentData = EnhancedPersistentImageData(
                originalImageFileName: originalFileName,
                editedImageFileName: editedFileName,
                transform: transform,
                createdAt: Date(),
                userId: userId,
                imageSize: editedImage.size
            )

            return persistentData
        }.value
    }

    private func saveImage(_ image: UIImage, fileName: String) -> Bool {
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

    func loadImage(fileName: String) -> UIImage? {
        let fileURL = FileManager.backgroundImagesDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        guard let imageData = try? Data(contentsOf: fileURL),
            let image = UIImage(data: imageData)
        else {
            return nil
        }

        return image
    }

    func deleteImage(fileName: String) {
        let fileURL = FileManager.backgroundImagesDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
    }

    func deleteImageSet(_ data: EnhancedPersistentImageData) {
        deleteImage(fileName: data.originalImageFileName)
        deleteImage(fileName: data.editedImageFileName)
    }
}

// MARK: - UserDefaults管理サービス

class UserDefaultsImageService {
    static let shared = UserDefaultsImageService()
    private let imagePersistenceService: ImagePersistenceService

    private init() {
        self.imagePersistenceService = ImagePersistenceService.shared
    }

    private let userBackgroundKey = "enhancedUserBackgroundImages"

    func saveBackgroundImageData(_ data: EnhancedPersistentImageData) {
        var savedData = loadAllBackgroundImageData()

        if let existingIndex = savedData.firstIndex(where: { $0.userId == data.userId }) {
            let existingData = savedData[existingIndex]

            // 同じファイル名の場合は削除しない（上書き保存のため）
            if existingData.editedImageFileName != data.editedImageFileName {
                imagePersistenceService.deleteImageSet(existingData)
            }
            savedData.remove(at: existingIndex)
        }

        savedData.append(data)

        if let encoded = try? JSONEncoder().encode(savedData) {
            UserDefaults.standard.set(encoded, forKey: userBackgroundKey)
        }
    }

    func loadBackgroundImageData(for userId: String) -> EnhancedPersistentImageData? {
        let allData = loadAllBackgroundImageData()
        return allData.first { $0.userId == userId }
    }

    private func loadAllBackgroundImageData() -> [EnhancedPersistentImageData] {
        guard let data = UserDefaults.standard.data(forKey: userBackgroundKey),
            let decoded = try? JSONDecoder().decode([EnhancedPersistentImageData].self, from: data)
        else {
            return []
        }
        return decoded
    }

    func deleteBackgroundImageData(for userId: String) {
        var savedData = loadAllBackgroundImageData()

        if let existingIndex = savedData.firstIndex(where: { $0.userId == userId }) {
            let existingData = savedData[existingIndex]
            imagePersistenceService.deleteImageSet(existingData)
            savedData.remove(at: existingIndex)
        }

        if let encoded = try? JSONEncoder().encode(savedData) {
            UserDefaults.standard.set(encoded, forKey: userBackgroundKey)
        }
    }
}

// MARK: - 必要なExtension

extension FileManager {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var backgroundImagesDirectory: URL {
        documentsDirectory.appendingPathComponent("BackgroundImages", isDirectory: true)
    }

    static func ensureBackgroundImagesDirectory() {
        let url = backgroundImagesDirectory
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}

extension UIImage {
    /// バックグラウンドでダウンサンプリング処理を実行
    /// - Parameters:
    ///   - pointSize: ターゲットサイズ（ポイント単位）
    ///   - scale: スケール係数（デフォルトは画面スケール）
    /// - Returns: ダウンサンプリング済み画像（失敗時はnil）
    func downsample(to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) async -> UIImage? {
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self, let data = self.pngData() else { return nil }

            let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions)
            else {
                return nil
            }

            let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
            let downsampleOptions =
                [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceShouldCacheImmediately: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels,
                ] as CFDictionary

            guard
                let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
                    imageSource, 0, downsampleOptions
                )
            else {
                return nil
            }

            return UIImage(cgImage: downsampledImage)
        }.value
    }
}

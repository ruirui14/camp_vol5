// Services/ImagePersistenceManager.swift
// 画像の永続化管理機能

import SwiftUI
import UIKit

// MARK: - 画像変換情報

struct ImageTransform: Codable {
    var scale: CGFloat = 1.0
    var normalizedOffset: CGPoint = .zero
    var backgroundColor: UIColor? = nil

    enum CodingKeys: String, CodingKey {
        case scale
        case normalizedOffset
        case backgroundColor
    }

    init(scale: CGFloat = 1.0, normalizedOffset: CGPoint = .zero, backgroundColor: UIColor? = nil) {
        self.scale = scale
        self.normalizedOffset = normalizedOffset
        self.backgroundColor = backgroundColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scale = try container.decode(CGFloat.self, forKey: .scale)
        normalizedOffset = try container.decode(CGPoint.self, forKey: .normalizedOffset)
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
    let thumbnailFileName: String
    let transform: ImageTransform
    let createdAt: Date
    let userId: String
    let imageSize: CGSize
}

// MARK: - 画像処理サービス

class ImageProcessingService {
    static let shared = ImageProcessingService()
    private init() {}

    func createEditedImage(
        from originalImage: UIImage,
        transform: ImageTransform,
        outputSize: CGSize
    ) -> UIImage? {
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
            let imageSize = aspectFitSize(originalImage.size, in: outputSize)

            // 中央配置の基準点を計算
            let centerX = outputSize.width / 2
            let centerY = outputSize.height / 2

            // 正規化されたオフセットを実際のピクセル値に変換
            let offsetX = transform.normalizedOffset.x * outputSize.width / 2
            let offsetY = transform.normalizedOffset.y * outputSize.height / 2

            // 最終的な描画矩形を計算
            let drawRect = CGRect(
                x: centerX - (imageSize.width * transform.scale) / 2 + offsetX,
                y: centerY - (imageSize.height * transform.scale) / 2 + offsetY,
                width: imageSize.width * transform.scale,
                height: imageSize.height * transform.scale
            )

            originalImage.draw(in: drawRect)
        }
    }

    func createThumbnail(
        from originalImage: UIImage,
        transform: ImageTransform,
        thumbnailSize: CGSize = CGSize(width: 300, height: 300)
    ) -> UIImage? {
        return createEditedImage(
            from: originalImage, transform: transform, outputSize: thumbnailSize
        )
    }

    func createFullSizeEditedImage(
        from originalImage: UIImage,
        transform: ImageTransform,
        targetScreenSize: CGSize
    ) -> UIImage? {
        let fullSize = CGSize(
            width: targetScreenSize.width * 2,
            height: targetScreenSize.height * 2
        )
        return createEditedImage(from: originalImage, transform: transform, outputSize: fullSize)
    }

    private func aspectFitSize(_ imageSize: CGSize, in containerSize: CGSize) -> CGSize {
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

    func saveEditedImageSet(
        originalImage: UIImage,
        transform: ImageTransform,
        userId: String,
        targetScreenSize: CGSize
    ) -> EnhancedPersistentImageData? {
        FileManager.ensureBackgroundImagesDirectory()

        let timestamp = UUID().uuidString
        let originalFileName = "\(userId)_original_\(timestamp).jpg"
        let editedFileName = "\(userId)_edited_\(timestamp).jpg"
        let thumbnailFileName = "\(userId)_thumb_\(timestamp).jpg"

        guard saveImage(originalImage, fileName: originalFileName) else {
            return nil
        }

        guard
            let editedImage = imageProcessor.createFullSizeEditedImage(
                from: originalImage,
                transform: transform,
                targetScreenSize: targetScreenSize
            ), saveImage(editedImage, fileName: editedFileName)
        else {
            deleteImage(fileName: originalFileName)
            return nil
        }

        guard
            let thumbnail = imageProcessor.createThumbnail(
                from: originalImage,
                transform: transform
            ), saveImage(thumbnail, fileName: thumbnailFileName)
        else {
            deleteImage(fileName: originalFileName)
            deleteImage(fileName: editedFileName)
            return nil
        }

        let persistentData = EnhancedPersistentImageData(
            originalImageFileName: originalFileName,
            editedImageFileName: editedFileName,
            thumbnailFileName: thumbnailFileName,
            transform: transform,
            createdAt: Date(),
            userId: userId,
            imageSize: editedImage.size
        )

        return persistentData
    }

    private func saveImage(_ image: UIImage, fileName: String) -> Bool {
        let fileURL = FileManager.backgroundImagesDirectory.appendingPathComponent(fileName)

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
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
        deleteImage(fileName: data.thumbnailFileName)
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
        print("=== UserDefaultsImageService.saveBackgroundImageData ===")
        print("Saving data for userId: \(data.userId)")
        print("Edited image filename: \(data.editedImageFileName)")

        var savedData = loadAllBackgroundImageData()
        print("Current saved data count: \(savedData.count)")

        for (index, savedItem) in savedData.enumerated() {
            print(
                "  [\(index)] UserId: \(savedItem.userId), EditedFile: \(savedItem.editedImageFileName)"
            )
        }

        if let existingIndex = savedData.firstIndex(where: { $0.userId == data.userId }) {
            let existingData = savedData[existingIndex]
            print("Found existing data for \(data.userId) at index \(existingIndex)")
            print("  Deleting old files: \(existingData.editedImageFileName)")
            imagePersistenceService.deleteImageSet(existingData)
            savedData.remove(at: existingIndex)
        } else {
            print("No existing data found for \(data.userId)")
        }

        savedData.append(data)
        print("After append, data count: \(savedData.count)")

        for (index, savedItem) in savedData.enumerated() {
            print(
                "  [\(index)] UserId: \(savedItem.userId), EditedFile: \(savedItem.editedImageFileName)"
            )
        }

        if let encoded = try? JSONEncoder().encode(savedData) {
            UserDefaults.standard.set(encoded, forKey: userBackgroundKey)
            print("Successfully saved to UserDefaults with key: \(userBackgroundKey)")
        } else {
            print("ERROR: Failed to encode data for UserDefaults")
        }
        print("=== End saveBackgroundImageData ===")
    }

    func loadBackgroundImageData(for userId: String) -> EnhancedPersistentImageData? {
        print("=== UserDefaultsImageService.loadBackgroundImageData ===")
        print("Loading data for userId: \(userId)")

        let allData = loadAllBackgroundImageData()
        print("Total data entries: \(allData.count)")

        for (index, savedItem) in allData.enumerated() {
            print(
                "  [\(index)] UserId: \(savedItem.userId), EditedFile: \(savedItem.editedImageFileName)"
            )
        }

        let result = allData.first { $0.userId == userId }
        if let result = result {
            print("Found data for \(userId): \(result.editedImageFileName)")
        } else {
            print("No data found for \(userId)")
        }
        print("=== End loadBackgroundImageData ===")

        return result
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

extension CGPoint: Codable {}
extension CGSize: Codable {}

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
    func downsample(to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        guard let data = jpegData(compressionQuality: 0.9) else { return nil }

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
    }
}

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
    let isAnimated: Bool  // GIFアニメーション画像かどうか

    // 後方互換性のための初期化
    init(
        originalImageFileName: String,
        editedImageFileName: String,
        transform: ImageTransform,
        createdAt: Date,
        userId: String,
        imageSize: CGSize,
        isAnimated: Bool = false
    ) {
        self.originalImageFileName = originalImageFileName
        self.editedImageFileName = editedImageFileName
        self.transform = transform
        self.createdAt = createdAt
        self.userId = userId
        self.imageSize = imageSize
        self.isAnimated = isAnimated
    }

    // デコード時の後方互換性
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        originalImageFileName = try container.decode(String.self, forKey: .originalImageFileName)
        editedImageFileName = try container.decode(String.self, forKey: .editedImageFileName)
        transform = try container.decode(ImageTransform.self, forKey: .transform)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        userId = try container.decode(String.self, forKey: .userId)
        imageSize = try container.decode(CGSize.self, forKey: .imageSize)
        // 古いデータにはisAnimatedがないので、デフォルトfalse
        isAnimated = try container.decodeIfPresent(Bool.self, forKey: .isAnimated) ?? false
    }
}

// MARK: - 画像永続化サービス

class ImagePersistenceService {
    static let shared = ImagePersistenceService()
    private let fileManager: FileManager

    private init() {
        self.fileManager = FileManager.default
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

    /// 画像データを読み込み（GIF対応）
    func loadImageData(fileName: String) -> Data? {
        let fileURL = FileManager.backgroundImagesDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return try? Data(contentsOf: fileURL)
    }

    /// 画像データがアニメーション画像かどうか判定
    func isAnimatedImage(data: Data) -> Bool {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return false
        }
        let frameCount = CGImageSourceGetCount(imageSource)
        return frameCount > 1
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

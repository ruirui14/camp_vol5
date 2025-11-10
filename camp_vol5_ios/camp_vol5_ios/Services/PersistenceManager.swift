//
//  PersistenceManager.swift
//  camp_vol5_ios
//
//  シンプルな画像永続化マネージャー
//

import Foundation
import SwiftUI
import UIKit

class PersistenceManager {
    static let shared = PersistenceManager()
    private let userDefaults = UserDefaults.standard

    private let backgroundImageKey = "backgroundImage"
    private let imageOffsetXKey = "imageOffsetX"
    private let imageOffsetYKey = "imageOffsetY"
    private let imageScaleKey = "imageScale"
    private let imageRotationKey = "imageRotation"
    private let heartOffsetXKey = "heartOffsetX"
    private let heartOffsetYKey = "heartOffsetY"
    private let heartSizeKey = "heartSize"
    private let backgroundColorRedKey = "backgroundColorRed"
    private let backgroundColorGreenKey = "backgroundColorGreen"
    private let backgroundColorBlueKey = "backgroundColorBlue"
    private let backgroundColorAlphaKey = "backgroundColorAlpha"
    private let isAnimatedImageKey = "isAnimatedImage"

    private init() {}

    // ユーザーID付きキーを生成するヘルパーメソッド
    private func userSpecificKey(_ baseKey: String, userId: String) -> String {
        return "\(baseKey)_\(userId)"
    }

    // MARK: - Background Image Management (GIF対応)

    // 画像をDocuments Directoryに保存（ユーザーID別）- GIF対応
    func saveBackgroundImage(_ image: UIImage, userId: String, imageData: Data? = nil) {
        // GIFデータが渡された場合、実際にアニメーションGIFかどうかを判定
        if let data = imageData {
            // アニメーションGIFかどうかを判定
            if isAnimatedGif(data: data) {
                saveBackgroundImageData(data, userId: userId, isAnimated: true)
                return
            }
            // 静止画像の場合はPNGとして保存（下に続く）
        }

        // 通常の画像として保存
        guard let data = image.pngData() else {
            return
        }

        saveBackgroundImageData(data, userId: userId, isAnimated: false)
    }

    // アニメーションGIFかどうかを判定するヘルパーメソッド
    private func isAnimatedGif(data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return false
        }

        let frameCount = CGImageSourceGetCount(source)

        // フレーム数が2以上の場合はアニメーションGIF
        return frameCount > 1
    }

    // 画像データを保存するプライベートメソッド
    private func saveBackgroundImageData(_ data: Data, userId: String, isAnimated: Bool) {
        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else {
            return
        }

        // ファイル拡張子を決定
        let fileExtension = isAnimated ? "gif" : "png"
        let fileName = "backgroundImage_\(userId).\(fileExtension)"
        let imagePath = documentsPath.appendingPathComponent(fileName)

        do {
            // 古いファイルを削除（異なる拡張子の可能性があるため）
            let oldPngPath = documentsPath.appendingPathComponent("backgroundImage_\(userId).png")
            let oldGifPath = documentsPath.appendingPathComponent("backgroundImage_\(userId).gif")
            try? FileManager.default.removeItem(at: oldPngPath)
            try? FileManager.default.removeItem(at: oldGifPath)

            // 新しいファイルを保存
            try data.write(to: imagePath)

            // アニメーション画像かどうかを保存
            let isAnimatedKey = userSpecificKey(isAnimatedImageKey, userId: userId)
            userDefaults.set(isAnimated, forKey: isAnimatedKey)
        } catch {
            // エラーは無視（デバッグ時に必要であればログを追加）
        }
    }

    // 保存された画像を読み込み（ユーザーID別）- GIF対応
    func loadBackgroundImage(userId: String) -> UIImage? {
        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else {
            return nil
        }

        // GIFファイルを優先的に探す
        let gifPath = documentsPath.appendingPathComponent("backgroundImage_\(userId).gif")
        if FileManager.default.fileExists(atPath: gifPath.path) {
            if let data = try? Data(contentsOf: gifPath),
                let image = UIImage(data: data)
            {
                return image
            }
        }

        // PNG画像を探す
        let pngPath = documentsPath.appendingPathComponent("backgroundImage_\(userId).png")
        if FileManager.default.fileExists(atPath: pngPath.path) {
            return UIImage(contentsOfFile: pngPath.path)
        }

        return nil
    }

    // 保存された画像データを読み込み（GIF対応）
    func loadBackgroundImageData(userId: String) -> Data? {
        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else {
            return nil
        }

        // GIFファイルを優先的に探す
        let gifPath = documentsPath.appendingPathComponent("backgroundImage_\(userId).gif")
        if FileManager.default.fileExists(atPath: gifPath.path) {
            return try? Data(contentsOf: gifPath)
        }

        // PNG画像を探す
        let pngPath = documentsPath.appendingPathComponent("backgroundImage_\(userId).png")
        if FileManager.default.fileExists(atPath: pngPath.path) {
            return try? Data(contentsOf: pngPath)
        }

        return nil
    }

    // アニメーション画像かどうかを確認
    func isAnimatedImage(userId: String) -> Bool {
        let isAnimatedKey = userSpecificKey(isAnimatedImageKey, userId: userId)
        return userDefaults.bool(forKey: isAnimatedKey)
    }

    // 画像の位置とスケール情報を保存（ユーザーID別）
    func saveImageTransform(offset: CGSize, scale: CGFloat, rotation: Double = 0.0, userId: String)
    {
        let offsetXKey = userSpecificKey(imageOffsetXKey, userId: userId)
        let offsetYKey = userSpecificKey(imageOffsetYKey, userId: userId)
        let scaleKey = userSpecificKey(imageScaleKey, userId: userId)
        let rotationKey = userSpecificKey(imageRotationKey, userId: userId)

        userDefaults.set(offset.width, forKey: offsetXKey)
        userDefaults.set(offset.height, forKey: offsetYKey)
        userDefaults.set(scale, forKey: scaleKey)
        userDefaults.set(rotation, forKey: rotationKey)
    }

    // 保存された画像の位置とスケール情報を読み込み（ユーザーID別）
    func loadImageTransform(userId: String) -> (offset: CGSize, scale: CGFloat, rotation: Double) {
        let offsetXKey = userSpecificKey(imageOffsetXKey, userId: userId)
        let offsetYKey = userSpecificKey(imageOffsetYKey, userId: userId)
        let scaleKey = userSpecificKey(imageScaleKey, userId: userId)
        let rotationKey = userSpecificKey(imageRotationKey, userId: userId)

        let offsetX = userDefaults.double(forKey: offsetXKey)
        let offsetY = userDefaults.double(forKey: offsetYKey)
        let scale = userDefaults.double(forKey: scaleKey)
        let rotation = userDefaults.double(forKey: rotationKey)

        let finalScale = scale == 0 ? 1.0 : scale
        return (
            offset: CGSize(width: offsetX, height: offsetY),
            scale: CGFloat(finalScale),
            rotation: rotation
        )
    }

    // 保存されたデータをすべて削除（ユーザーID別）
    func clearAllData(userId: String) {
        // 画像ファイルを削除（GIF/PNG両方）
        if let documentsPath = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first {
            let pngPath = documentsPath.appendingPathComponent("backgroundImage_\(userId).png")
            let gifPath = documentsPath.appendingPathComponent("backgroundImage_\(userId).gif")
            try? FileManager.default.removeItem(at: pngPath)
            try? FileManager.default.removeItem(at: gifPath)
        }

        // UserDefaultsからユーザーID別のデータを削除
        let offsetXKey = userSpecificKey(imageOffsetXKey, userId: userId)
        let offsetYKey = userSpecificKey(imageOffsetYKey, userId: userId)
        let scaleKey = userSpecificKey(imageScaleKey, userId: userId)
        let rotationKey = userSpecificKey(imageRotationKey, userId: userId)
        let heartXKey = userSpecificKey(heartOffsetXKey, userId: userId)
        let heartYKey = userSpecificKey(heartOffsetYKey, userId: userId)
        let sizeKey = userSpecificKey(heartSizeKey, userId: userId)
        let colorRedKey = userSpecificKey(backgroundColorRedKey, userId: userId)
        let colorGreenKey = userSpecificKey(backgroundColorGreenKey, userId: userId)
        let colorBlueKey = userSpecificKey(backgroundColorBlueKey, userId: userId)
        let colorAlphaKey = userSpecificKey(backgroundColorAlphaKey, userId: userId)
        let animatedKey = userSpecificKey(isAnimatedImageKey, userId: userId)

        userDefaults.removeObject(forKey: offsetXKey)
        userDefaults.removeObject(forKey: offsetYKey)
        userDefaults.removeObject(forKey: scaleKey)
        userDefaults.removeObject(forKey: rotationKey)
        userDefaults.removeObject(forKey: heartXKey)
        userDefaults.removeObject(forKey: heartYKey)
        userDefaults.removeObject(forKey: sizeKey)
        userDefaults.removeObject(forKey: colorRedKey)
        userDefaults.removeObject(forKey: colorGreenKey)
        userDefaults.removeObject(forKey: colorBlueKey)
        userDefaults.removeObject(forKey: colorAlphaKey)
        userDefaults.removeObject(forKey: animatedKey)
    }

    // 保存されたデータをすべて削除（レガシー用）
    func clearAllData() {
        // 画像ファイルを削除
        if let documentsPath = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first {
            let imagePath = documentsPath.appendingPathComponent("backgroundImage.png")
            try? FileManager.default.removeItem(at: imagePath)
        }

        // UserDefaultsからデータを削除
        userDefaults.removeObject(forKey: imageOffsetXKey)
        userDefaults.removeObject(forKey: imageOffsetYKey)
        userDefaults.removeObject(forKey: imageScaleKey)
        userDefaults.removeObject(forKey: imageRotationKey)
        userDefaults.removeObject(forKey: heartOffsetXKey)
        userDefaults.removeObject(forKey: heartOffsetYKey)
        userDefaults.removeObject(forKey: heartSizeKey)
    }

    // ハートの位置を保存（ユーザーID別）
    func saveHeartPosition(_ offset: CGSize, userId: String) {
        let heartOffsetXKey = userSpecificKey(self.heartOffsetXKey, userId: userId)
        let heartOffsetYKey = userSpecificKey(self.heartOffsetYKey, userId: userId)

        userDefaults.set(Double(offset.width), forKey: heartOffsetXKey)
        userDefaults.set(Double(offset.height), forKey: heartOffsetYKey)
    }

    // ハートの位置を読み込み（ユーザーID別）
    func loadHeartPosition(userId: String) -> CGSize {
        let heartOffsetXKey = userSpecificKey(self.heartOffsetXKey, userId: userId)
        let heartOffsetYKey = userSpecificKey(self.heartOffsetYKey, userId: userId)

        let offsetX = userDefaults.double(forKey: heartOffsetXKey)
        let offsetY = userDefaults.double(forKey: heartOffsetYKey)
        return CGSize(width: offsetX, height: offsetY)
    }

    // MARK: - Heart Size Management

    /// ハートのサイズを保存（ユーザーID別）
    func saveHeartSize(_ size: CGFloat, userId: String) {
        let heartSizeKey = userSpecificKey(self.heartSizeKey, userId: userId)
        userDefaults.set(Double(size), forKey: heartSizeKey)
    }

    /// ハートのサイズを読み込み（ユーザーID別）
    func loadHeartSize(userId: String) -> CGFloat {
        let heartSizeKey = userSpecificKey(self.heartSizeKey, userId: userId)
        let size = userDefaults.double(forKey: heartSizeKey)
        // デフォルトサイズは105（元のサイズ）
        let heartSize = size == 0 ? 105.0 : size
        return CGFloat(heartSize)
    }

    // MARK: - Background Color Persistence

    // 背景色を保存（ユーザーID別）
    func saveBackgroundColor(_ color: Color, userId: String) {
        let redKey = userSpecificKey(backgroundColorRedKey, userId: userId)
        let greenKey = userSpecificKey(backgroundColorGreenKey, userId: userId)
        let blueKey = userSpecificKey(backgroundColorBlueKey, userId: userId)
        let alphaKey = userSpecificKey(backgroundColorAlphaKey, userId: userId)

        if color == Color.clear {
            // クリア（デフォルト）の場合は保存されたデータを削除
            userDefaults.removeObject(forKey: redKey)
            userDefaults.removeObject(forKey: greenKey)
            userDefaults.removeObject(forKey: blueKey)
            userDefaults.removeObject(forKey: alphaKey)
        } else {
            // UIColorに変換してRGBA値を取得
            let uiColor = UIColor(color)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            userDefaults.set(Double(red), forKey: redKey)
            userDefaults.set(Double(green), forKey: greenKey)
            userDefaults.set(Double(blue), forKey: blueKey)
            userDefaults.set(Double(alpha), forKey: alphaKey)
        }
    }

    // 背景色を読み込み（ユーザーID別）
    func loadBackgroundColor(userId: String) -> Color {
        let redKey = userSpecificKey(backgroundColorRedKey, userId: userId)
        let greenKey = userSpecificKey(backgroundColorGreenKey, userId: userId)
        let blueKey = userSpecificKey(backgroundColorBlueKey, userId: userId)
        let alphaKey = userSpecificKey(backgroundColorAlphaKey, userId: userId)

        // デフォルト値がある場合は保存された色を復元
        if userDefaults.object(forKey: redKey) != nil {
            let red = userDefaults.double(forKey: redKey)
            let green = userDefaults.double(forKey: greenKey)
            let blue = userDefaults.double(forKey: blueKey)
            let alpha = userDefaults.double(forKey: alphaKey)

            let color = Color(
                red: red,
                green: green,
                blue: blue,
                opacity: alpha
            )
            return color
        }

        // デフォルトはクリア（グラデーション背景使用）
        return Color.clear
    }
}

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

    private init() {}

    // ユーザーID付きキーを生成するヘルパーメソッド
    private func userSpecificKey(_ baseKey: String, userId: String) -> String {
        return "\(baseKey)_\(userId)"
    }

    // 画像をDocuments Directoryに保存（ユーザーID別）
    func saveBackgroundImage(_ image: UIImage, userId: String) {
        print("=== PersistenceManager.saveBackgroundImage ===")
        print("UserId: \(userId)")

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("ERROR: Failed to convert image to JPEG data")
            return
        }

        if let documentsPath = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first {
            let fileName = "backgroundImage_\(userId).jpg"
            let imagePath = documentsPath.appendingPathComponent(fileName)
            print("Saving image to: \(imagePath.path)")

            do {
                try data.write(to: imagePath)
                print("Successfully saved image with size: \(data.count) bytes")
            } catch {
                print("ERROR: Failed to save image: \(error)")
            }
        } else {
            print("ERROR: Failed to get documents directory")
        }
        print("=== End saveBackgroundImage ===")
    }

    // 保存された画像を読み込み（ユーザーID別）
    func loadBackgroundImage(userId: String) -> UIImage? {
        print("=== PersistenceManager.loadBackgroundImage ===")
        print("UserId: \(userId)")

        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else {
            print("ERROR: Failed to get documents directory")
            return nil
        }

        let fileName = "backgroundImage_\(userId).jpg"
        let imagePath = documentsPath.appendingPathComponent(fileName)
        print("Looking for image at: \(imagePath.path)")

        if FileManager.default.fileExists(atPath: imagePath.path) {
            print("File exists, loading image...")
            if let image = UIImage(contentsOfFile: imagePath.path) {
                print("Successfully loaded image with size: \(image.size)")
                return image
            } else {
                print("ERROR: Failed to create UIImage from file")
                return nil
            }
        } else {
            print("File does not exist")
            return nil
        }
    }

    // 画像の位置とスケール情報を保存（ユーザーID別）
    func saveImageTransform(offset: CGSize, scale: CGFloat, rotation: Double = 0.0, userId: String) {
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

        return (
            offset: CGSize(width: offsetX, height: offsetY),
            scale: scale == 0 ? 1.0 : scale,
            rotation: rotation
        )
    }

    // 保存されたデータをすべて削除
    func clearAllData() {
        // 画像ファイルを削除
        if let documentsPath = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first {
            let imagePath = documentsPath.appendingPathComponent("backgroundImage.jpg")
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

        let x = userDefaults.double(forKey: heartOffsetXKey)
        let y = userDefaults.double(forKey: heartOffsetYKey)
        return CGSize(width: x, height: y)
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

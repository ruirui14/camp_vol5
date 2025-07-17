//
//  PersistenceManager.swift
//  camp_vol5_ios
//
//  シンプルな画像永続化マネージャー
//

import Foundation
import UIKit

class PersistenceManager {
    static let shared = PersistenceManager()
    private let userDefaults = UserDefaults.standard

    private let backgroundImageKey = "backgroundImage"
    private let imageOffsetXKey = "imageOffsetX"
    private let imageOffsetYKey = "imageOffsetY"
    private let imageScaleKey = "imageScale"
    private let heartOffsetXKey = "heartOffsetX"
    private let heartOffsetYKey = "heartOffsetY"

    private init() {}

    // 画像をDocuments Directoryに保存
    func saveBackgroundImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        if let documentsPath = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first {
            let imagePath = documentsPath.appendingPathComponent("backgroundImage.jpg")
            try? data.write(to: imagePath)
        }
    }

    // 保存された画像を読み込み
    func loadBackgroundImage() -> UIImage? {
        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
        else { return nil }

        let imagePath = documentsPath.appendingPathComponent("backgroundImage.jpg")

        if FileManager.default.fileExists(atPath: imagePath.path) {
            return UIImage(contentsOfFile: imagePath.path)
        }

        return nil
    }

    // 画像の位置とスケール情報を保存
    func saveImageTransform(offset: CGSize, scale: CGFloat) {
        userDefaults.set(offset.width, forKey: imageOffsetXKey)
        userDefaults.set(offset.height, forKey: imageOffsetYKey)
        userDefaults.set(scale, forKey: imageScaleKey)
    }

    // 保存された画像の位置とスケール情報を読み込み
    func loadImageTransform() -> (offset: CGSize, scale: CGFloat) {
        let offsetX = userDefaults.double(forKey: imageOffsetXKey)
        let offsetY = userDefaults.double(forKey: imageOffsetYKey)
        let scale = userDefaults.double(forKey: imageScaleKey)

        return (
            offset: CGSize(width: offsetX, height: offsetY),
            scale: scale == 0 ? 1.0 : scale
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
        userDefaults.removeObject(forKey: heartOffsetXKey)
        userDefaults.removeObject(forKey: heartOffsetYKey)
    }
    
    // ハートの位置を保存
    func saveHeartPosition(_ offset: CGSize) {
        userDefaults.set(Double(offset.width), forKey: heartOffsetXKey)
        userDefaults.set(Double(offset.height), forKey: heartOffsetYKey)
    }
    
    // ハートの位置を読み込み
    func loadHeartPosition() -> CGSize {
        let x = userDefaults.double(forKey: heartOffsetXKey)
        let y = userDefaults.double(forKey: heartOffsetYKey)
        return CGSize(width: x, height: y)
    }
}

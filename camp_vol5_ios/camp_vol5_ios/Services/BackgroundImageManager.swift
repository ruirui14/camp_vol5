// Services/BackgroundImageManager.swift
// 背景画像管理サービス

import SwiftUI
import UIKit

// MARK: - 背景画像管理マネージャー
class BackgroundImageManager: ObservableObject {
    @Published var currentEditedImage: UIImage?
    @Published var currentThumbnail: UIImage?
    @Published var currentOriginalImage: UIImage?
    @Published var currentTransform: ImageTransform = ImageTransform()
    @Published var isLoading = false
    @Published var isSaving = false
    
    private let userId: String
    private let persistenceManager = EnhancedImagePersistenceManager.shared
    private let userDefaultsManager = EnhancedUserDefaultsManager.shared
    
    init(userId: String) {
        self.userId = userId
        loadPersistedImages()
    }
    
    private func loadPersistedImages() {
        print("📂 loadPersistedImages開始 - userId: \(userId)")
        isLoading = true
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            if let savedData = self.userDefaultsManager.loadBackgroundImageData(for: self.userId) {
                print("📊 保存データ発見:")
                print("   - 作成日時: \(savedData.createdAt)")
                print("   - 画像サイズ: \(savedData.imageSize)")
                print("   - 変換情報:")
                print("     - スケール: \(savedData.transform.scale)")
                print("     - オフセット: \(savedData.transform.normalizedOffset)")
                print("     - 背景色: \(savedData.transform.backgroundColor?.description ?? "なし")")
                
                let editedImage = self.persistenceManager.loadImage(
                    fileName: savedData.editedImageFileName)
                let thumbnail = self.persistenceManager.loadImage(
                    fileName: savedData.thumbnailFileName)
                let originalImage = self.persistenceManager.loadImage(
                    fileName: savedData.originalImageFileName)
                
                print("🖼️ 画像読み込み結果:")
                print("   - 編集済み画像: \(editedImage != nil ? "成功(\(editedImage!.size))" : "失敗")")
                print("   - サムネイル: \(thumbnail != nil ? "成功(\(thumbnail!.size))" : "失敗")")
                print("   - 元画像: \(originalImage != nil ? "成功(\(originalImage!.size))" : "失敗")")
                
                DispatchQueue.main.async {
                    self.currentEditedImage = editedImage
                    self.currentThumbnail = thumbnail
                    self.currentOriginalImage = originalImage
                    self.currentTransform = savedData.transform
                    self.isLoading = false
                    
                    print("✅ 背景画像セット復元完了: \(self.userId)")
                    print("🔄 復元後の状態:")
                    print("   - currentOriginalImage: \(self.currentOriginalImage != nil ? "あり(\(self.currentOriginalImage!.size))" : "なし")")
                    print("   - currentTransform.scale: \(self.currentTransform.scale)")
                    print("   - currentTransform.offset: \(self.currentTransform.normalizedOffset)")
                    print("   - currentTransform.backgroundColor: \(self.currentTransform.backgroundColor?.description ?? "なし")")
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("ℹ️ 保存された背景画像なし: \(self.userId)")
                }
            }
        }
    }
    
    func setOriginalImage(_ image: UIImage) {
        print("🔧 ImageManager: setOriginalImage 開始 - 元サイズ: \(image.size)")
        
        let screenSize = UIScreen.main.bounds.size
        let maxSize = CGSize(width: screenSize.width * 2, height: screenSize.height * 2)
        
        guard let processedImage = image.downsample(to: maxSize) else {
            print("❌ ImageManager: 画像のダウンサンプリングに失敗")
            return
        }
        
        print("✅ ImageManager: ダウンサンプル成功 - 処理後サイズ: \(processedImage.size)")
        
        self.currentOriginalImage = processedImage
        self.currentTransform = ImageTransform()
        
        print("✅ ImageManager: 元画像設定完了")
    }
    
    func saveEditedResult(_ transform: ImageTransform) {
        guard let originalImage = currentOriginalImage else {
            print("❌ 元画像が見つかりません")
            return
        }
        
        isSaving = true
        self.currentTransform = transform
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let screenSize = UIScreen.main.bounds.size
            
            guard
                let persistentData = self.persistenceManager.saveEditedImageSet(
                    originalImage: originalImage,
                    transform: transform,
                    userId: self.userId,
                    targetScreenSize: screenSize
                )
            else {
                DispatchQueue.main.async {
                    self.isSaving = false
                    print("❌ 編集結果の保存に失敗")
                }
                return
            }
            
            self.userDefaultsManager.saveBackgroundImageData(persistentData)
            
            let editedImage = self.persistenceManager.loadImage(
                fileName: persistentData.editedImageFileName)
            let thumbnail = self.persistenceManager.loadImage(
                fileName: persistentData.thumbnailFileName)
            
            DispatchQueue.main.async {
                self.currentEditedImage = editedImage
                self.currentThumbnail = thumbnail
                self.isSaving = false
                print("✅ 編集結果の保存・読み込み完了")
            }
        }
    }
    
    func saveEditingState(selectedImage: UIImage?, transform: ImageTransform) {
        print("🔄 saveEditingState開始 - userId: \(userId)")
        print("📝 保存データ:")
        print("   - 選択画像: \(selectedImage != nil ? "あり(\(selectedImage!.size))" : "なし")")
        print("   - スケール: \(transform.scale)")
        print("   - オフセット: \(transform.normalizedOffset)")
        print("   - 背景色: \(transform.backgroundColor?.description ?? "なし")")
        
        // 新しく選択された画像がある場合は元画像として設定
        if let newImage = selectedImage {
            print("🖼️ 新しい画像を元画像として設定")
            setOriginalImage(newImage)
        }
        
        // 編集中の変換情報を保存
        self.currentTransform = transform
        print("💾 変換情報をcurrentTransformに保存")
        
        // 元画像がある場合のみ完全な保存処理を実行
        if currentOriginalImage != nil {
            print("✅ 元画像あり - 完全保存処理開始")
            saveEditedResult(transform)
        } else {
            print("ℹ️ 元画像がないため変換情報のみ保存")
        }
    }
    
    func resetBackgroundImage() {
        if let savedData = userDefaultsManager.loadBackgroundImageData(for: userId) {
            persistenceManager.deleteImageSet(savedData)
        }
        userDefaultsManager.deleteBackgroundImageData(for: userId)
        
        currentEditedImage = nil
        currentThumbnail = nil
        currentOriginalImage = nil
        currentTransform = ImageTransform()
        
        print("🔄 背景画像リセット完了: \(userId)")
    }
    
    func getOriginalImageForReEdit() -> UIImage? {
        return currentOriginalImage
    }
    
    func getFinalDisplayImage() -> UIImage? {
        return currentEditedImage
    }
    
    func getThumbnailImage() -> UIImage? {
        return currentThumbnail
    }
    
    func refreshFromStorage() {
        loadPersistedImages()
    }
}
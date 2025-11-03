// Views/Components/AnimatedImageView.swift
// アニメーションGIF表示用のUIViewRepresentableコンポーネント
// UIImageViewをラップしてGIFアニメーションをSwiftUIで表示可能にする
// バックグラウンド処理とキャッシュ機能により、パフォーマンスを最適化

import ImageIO
import SwiftUI
import UIKit

/// GIFアニメーションを表示するためのSwiftUIビュー
struct AnimatedImageView: UIViewRepresentable {
    let imageData: Data
    let contentMode: UIView.ContentMode

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // キャッシュをチェック
        let cacheKey = imageData.hashValue
        if let cachedImage = AnimatedImageCache.shared.getImage(forKey: cacheKey) {
            uiView.image = cachedImage
            return
        }

        // バックグラウンドでGIFアニメーションを作成
        Task.detached(priority: .userInitiated) {
            let animatedImage = await createAnimatedImageAsync(from: imageData)

            await MainActor.run {
                // キャッシュに保存
                if let animatedImage = animatedImage {
                    AnimatedImageCache.shared.setImage(animatedImage, forKey: cacheKey)
                    uiView.image = animatedImage
                }
            }
        }
    }

    /// バックグラウンドでGIFデータからアニメーション付きUIImageを作成
    private func createAnimatedImageAsync(from data: Data) async -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var duration: TimeInterval = 0

        for index in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) {
                // フレームの表示時間を取得
                let frameDuration = getFrameDuration(from: source, at: index)
                duration += frameDuration

                images.append(UIImage(cgImage: cgImage))
            }
        }

        // アニメーション画像を作成
        return UIImage.animatedImage(with: images, duration: duration)
    }

    /// GIFの各フレームの表示時間を取得
    private func getFrameDuration(from source: CGImageSource, at index: Int) -> TimeInterval {
        var frameDuration: TimeInterval = 0.1  // デフォルト値

        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
                as? [String: Any],
            let gifProperties = properties[kCGImagePropertyGIFDictionary as String]
                as? [String: Any]
        else {
            return frameDuration
        }

        // UnclampedDelayTimeを優先的に使用
        if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String]
            as? NSNumber
        {
            frameDuration = unclampedDelay.doubleValue
        } else if let delay = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
            frameDuration = delay.doubleValue
        }

        // 最小値を設定（0.02秒 = 50fps）
        if frameDuration < 0.02 {
            frameDuration = 0.1
        }

        return frameDuration
    }
}

/// GIFアニメーション画像のキャッシュマネージャー
/// メモリ効率のためNSCacheを使用
class AnimatedImageCache {
    static let shared = AnimatedImageCache()
    private let cache = NSCache<NSNumber, UIImage>()

    private init() {
        // メモリ警告時にキャッシュをクリア
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        // キャッシュの最大数を設定（約10個のGIF画像）
        cache.countLimit = 10
    }

    func getImage(forKey key: Int) -> UIImage? {
        return cache.object(forKey: NSNumber(value: key))
    }

    func setImage(_ image: UIImage, forKey key: Int) {
        cache.setObject(image, forKey: NSNumber(value: key))
    }

    @objc private func clearCache() {
        cache.removeAllObjects()
    }
}

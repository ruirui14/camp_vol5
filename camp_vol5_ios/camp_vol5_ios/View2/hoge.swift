// import Photos
// import PhotosUI
// import SwiftUI
// import UIKit

// // MARK: - Enhanced Image Processing
// class AdvancedImageProcessor {

//     // 編集結果を実際の画像として生成
//     static func createEditedImage(
//         from originalImage: UIImage,
//         transform: ImageTransform,
//         outputSize: CGSize
//     ) -> UIImage? {

//         let renderer = UIGraphicsImageRenderer(size: outputSize)

//         return renderer.image { context in
//             let cgContext = context.cgContext

//             // 背景を透明に設定
//             cgContext.clear(CGRect(origin: .zero, size: outputSize))

//             // 変換の適用
//             cgContext.translateBy(x: outputSize.width / 2, y: outputSize.height / 2)
//             cgContext.scaleBy(x: transform.scale, y: transform.scale)

//             let offset = transform.actualOffset(for: outputSize)
//             cgContext.translateBy(x: offset.width, y: offset.height)
//             cgContext.translateBy(x: -outputSize.width / 2, y: -outputSize.height / 2)

//             // 画像のアスペクト比を維持してフィット
//             let imageSize = aspectFitSize(originalImage.size, in: outputSize)
//             let drawRect = CGRect(
//                 x: (outputSize.width - imageSize.width) / 2,
//                 y: (outputSize.height - imageSize.height) / 2,
//                 width: imageSize.width,
//                 height: imageSize.height
//             )

//             // 画像を描画
//             originalImage.draw(in: drawRect)
//         }
//     }

//     // プレビュー用の小さなサムネイル生成
//     static func createThumbnail(
//         from originalImage: UIImage,
//         transform: ImageTransform,
//         thumbnailSize: CGSize = CGSize(width: 300, height: 300)
//     ) -> UIImage? {
//         return createEditedImage(
//             from: originalImage, transform: transform, outputSize: thumbnailSize)
//     }

//     // フルサイズの編集済み画像生成
//     static func createFullSizeEditedImage(
//         from originalImage: UIImage,
//         transform: ImageTransform,
//         targetScreenSize: CGSize
//     ) -> UIImage? {
//         // 画面サイズの2倍で高品質版を作成
//         let fullSize = CGSize(
//             width: targetScreenSize.width * 2,
//             height: targetScreenSize.height * 2
//         )
//         return createEditedImage(from: originalImage, transform: transform, outputSize: fullSize)
//     }

//     private static func aspectFitSize(_ imageSize: CGSize, in containerSize: CGSize) -> CGSize {
//         let scale = min(
//             containerSize.width / imageSize.width,
//             containerSize.height / imageSize.height)
//         return CGSize(
//             width: imageSize.width * scale,
//             height: imageSize.height * scale)
//     }
// }

// // MARK: - Enhanced Persistent Data
// struct EnhancedPersistentImageData: Codable {
//     let originalImageFileName: String  // 元画像
//     let editedImageFileName: String  // 編集済み画像
//     let thumbnailFileName: String  // サムネイル
//     let transform: ImageTransform  // 変換情報（デバッグ用）
//     let createdAt: Date
//     let userId: String
//     let imageSize: CGSize  // 保存時の画像サイズ
// }

// // MARK: - Enhanced Image Persistence Manager
// class EnhancedImagePersistenceManager {
//     static let shared = EnhancedImagePersistenceManager()
//     private init() {}

//     // 編集結果を複数形式で保存
//     func saveEditedImageSet(
//         originalImage: UIImage,
//         transform: ImageTransform,
//         userId: String,
//         targetScreenSize: CGSize
//     ) -> EnhancedPersistentImageData? {

//         FileManager.ensureBackgroundImagesDirectory()

//         let timestamp = UUID().uuidString
//         let originalFileName = "\(userId)_original_\(timestamp).jpg"
//         let editedFileName = "\(userId)_edited_\(timestamp).jpg"
//         let thumbnailFileName = "\(userId)_thumb_\(timestamp).jpg"

//         // 1. 元画像を保存
//         guard saveImage(originalImage, fileName: originalFileName) else {
//             print("❌ 元画像の保存に失敗")
//             return nil
//         }

//         // 2. 編集済み画像を生成・保存
//         guard
//             let editedImage = AdvancedImageProcessor.createFullSizeEditedImage(
//                 from: originalImage,
//                 transform: transform,
//                 targetScreenSize: targetScreenSize
//             ), saveImage(editedImage, fileName: editedFileName)
//         else {
//             print("❌ 編集済み画像の保存に失敗")
//             deleteImage(fileName: originalFileName)  // クリーンアップ
//             return nil
//         }

//         // 3. サムネイルを生成・保存
//         guard
//             let thumbnail = AdvancedImageProcessor.createThumbnail(
//                 from: originalImage,
//                 transform: transform
//             ), saveImage(thumbnail, fileName: thumbnailFileName)
//         else {
//             print("❌ サムネイルの保存に失敗")
//             deleteImage(fileName: originalFileName)
//             deleteImage(fileName: editedFileName)
//             return nil
//         }

//         let persistentData = EnhancedPersistentImageData(
//             originalImageFileName: originalFileName,
//             editedImageFileName: editedFileName,
//             thumbnailFileName: thumbnailFileName,
//             transform: transform,
//             createdAt: Date(),
//             userId: userId,
//             imageSize: editedImage.size
//         )

//         print("✅ 編集画像セット保存完了")
//         print("  - 元画像: \(originalFileName)")
//         print("  - 編集済み: \(editedFileName)")
//         print("  - サムネイル: \(thumbnailFileName)")

//         return persistentData
//     }

//     private func saveImage(_ image: UIImage, fileName: String) -> Bool {
//         let fileURL = FileManager.backgroundImagesDirectory.appendingPathComponent(fileName)

//         guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//             return false
//         }

//         do {
//             try imageData.write(to: fileURL)
//             return true
//         } catch {
//             print("❌ 画像保存エラー: \(error)")
//             return false
//         }
//     }

//     func loadImage(fileName: String) -> UIImage? {
//         let fileURL = FileManager.backgroundImagesDirectory.appendingPathComponent(fileName)

//         guard FileManager.default.fileExists(atPath: fileURL.path) else {
//             return nil
//         }

//         guard let imageData = try? Data(contentsOf: fileURL),
//             let image = UIImage(data: imageData)
//         else {
//             return nil
//         }

//         return image
//     }

//     func deleteImage(fileName: String) {
//         let fileURL = FileManager.backgroundImagesDirectory.appendingPathComponent(fileName)
//         try? FileManager.default.removeItem(at: fileURL)
//     }

//     // 画像セット全体を削除
//     func deleteImageSet(_ data: EnhancedPersistentImageData) {
//         deleteImage(fileName: data.originalImageFileName)
//         deleteImage(fileName: data.editedImageFileName)
//         deleteImage(fileName: data.thumbnailFileName)
//         print("✅ 画像セット削除完了: \(data.userId)")
//     }
// }

// // MARK: - Enhanced UserDefaults Manager
// class EnhancedUserDefaultsManager {
//     static let shared = EnhancedUserDefaultsManager()
//     private init() {}

//     private let userBackgroundKey = "enhancedUserBackgroundImages"

//     func saveBackgroundImageData(_ data: EnhancedPersistentImageData) {
//         var savedData = loadAllBackgroundImageData()

//         // 既存データの削除（ファイルも削除）
//         if let existingIndex = savedData.firstIndex(where: { $0.userId == data.userId }) {
//             let existingData = savedData[existingIndex]
//             EnhancedImagePersistenceManager.shared.deleteImageSet(existingData)
//             savedData.remove(at: existingIndex)
//         }

//         savedData.append(data)

//         if let encoded = try? JSONEncoder().encode(savedData) {
//             UserDefaults.standard.set(encoded, forKey: userBackgroundKey)
//             print("✅ 拡張背景画像データ保存成功: \(data.userId)")
//         }
//     }

//     func loadBackgroundImageData(for userId: String) -> EnhancedPersistentImageData? {
//         let allData = loadAllBackgroundImageData()
//         return allData.first { $0.userId == userId }
//     }

//     private func loadAllBackgroundImageData() -> [EnhancedPersistentImageData] {
//         guard let data = UserDefaults.standard.data(forKey: userBackgroundKey),
//             let decoded = try? JSONDecoder().decode([EnhancedPersistentImageData].self, from: data)
//         else {
//             return []
//         }
//         return decoded
//     }

//     func deleteBackgroundImageData(for userId: String) {
//         var savedData = loadAllBackgroundImageData()

//         if let existingIndex = savedData.firstIndex(where: { $0.userId == userId }) {
//             let existingData = savedData[existingIndex]
//             EnhancedImagePersistenceManager.shared.deleteImageSet(existingData)
//             savedData.remove(at: existingIndex)
//         }

//         if let encoded = try? JSONEncoder().encode(savedData) {
//             UserDefaults.standard.set(encoded, forKey: userBackgroundKey)
//         }
//     }
// }

// // MARK: - Enhanced Background Image Manager
// class EnhancedBackgroundImageManager: ObservableObject {
//     @Published var currentEditedImage: UIImage?  // 編集済み画像（表示用）
//     @Published var currentThumbnail: UIImage?  // サムネイル
//     @Published var currentOriginalImage: UIImage?  // 元画像（再編集用）
//     @Published var currentTransform: ImageTransform = ImageTransform()
//     @Published var isLoading = false
//     @Published var isSaving = false

//     private let userId: String
//     private let persistenceManager = EnhancedImagePersistenceManager.shared
//     private let userDefaultsManager = EnhancedUserDefaultsManager.shared

//     init(userId: String) {
//         self.userId = userId
//         loadPersistedImages()
//     }

//     private func loadPersistedImages() {
//         isLoading = true

//         DispatchQueue.global(qos: .background).async { [weak self] in
//             guard let self = self else { return }

//             if let savedData = self.userDefaultsManager.loadBackgroundImageData(for: self.userId) {

//                 let editedImage = self.persistenceManager.loadImage(
//                     fileName: savedData.editedImageFileName)
//                 let thumbnail = self.persistenceManager.loadImage(
//                     fileName: savedData.thumbnailFileName)
//                 let originalImage = self.persistenceManager.loadImage(
//                     fileName: savedData.originalImageFileName)

//                 DispatchQueue.main.async {
//                     self.currentEditedImage = editedImage
//                     self.currentThumbnail = thumbnail
//                     self.currentOriginalImage = originalImage
//                     self.currentTransform = savedData.transform
//                     self.isLoading = false

//                     print("✅ 拡張背景画像セット復元完了: \(self.userId)")
//                     print("  - 編集済み画像: \(editedImage?.size ?? .zero)")
//                     print("  - サムネイル: \(thumbnail?.size ?? .zero)")
//                 }
//             } else {
//                 DispatchQueue.main.async {
//                     self.isLoading = false
//                     print("ℹ️ 保存された背景画像なし: \(self.userId)")
//                 }
//             }
//         }
//     }

//     // 新しい画像を設定（編集前）
//     func setOriginalImage(_ image: UIImage) {
//         print("🔧 ImageManager: setOriginalImage 開始 - 元サイズ: \(image.size)")

//         let screenSize = UIScreen.main.bounds.size
//         let maxSize = CGSize(width: screenSize.width * 2, height: screenSize.height * 2)

//         print("🔧 ImageManager: ダウンサンプル開始 - 目標サイズ: \(maxSize)")

//         guard let processedImage = image.downsample(to: maxSize) else {
//             print("❌ ImageManager: 画像のダウンサンプリングに失敗")
//             return
//         }

//         print("✅ ImageManager: ダウンサンプル成功 - 処理後サイズ: \(processedImage.size)")

//         self.currentOriginalImage = processedImage
//         self.currentTransform = ImageTransform()

//         print("✅ ImageManager: 元画像設定完了")
//     }

//     // 編集完了時：実際の画像として保存
//     func saveEditedResult(_ transform: ImageTransform) {
//         guard let originalImage = currentOriginalImage else {
//             print("❌ 元画像が見つかりません")
//             return
//         }

//         isSaving = true
//         self.currentTransform = transform

//         DispatchQueue.global(qos: .background).async { [weak self] in
//             guard let self = self else { return }

//             let screenSize = UIScreen.main.bounds.size

//             guard
//                 let persistentData = self.persistenceManager.saveEditedImageSet(
//                     originalImage: originalImage,
//                     transform: transform,
//                     userId: self.userId,
//                     targetScreenSize: screenSize
//                 )
//             else {
//                 DispatchQueue.main.async {
//                     self.isSaving = false
//                     print("❌ 編集結果の保存に失敗")
//                 }
//                 return
//             }

//             // UserDefaultsに保存
//             self.userDefaultsManager.saveBackgroundImageData(persistentData)

//             // 編集済み画像を読み込んで表示用に設定
//             let editedImage = self.persistenceManager.loadImage(
//                 fileName: persistentData.editedImageFileName)
//             let thumbnail = self.persistenceManager.loadImage(
//                 fileName: persistentData.thumbnailFileName)

//             DispatchQueue.main.async {
//                 self.currentEditedImage = editedImage
//                 self.currentThumbnail = thumbnail
//                 self.isSaving = false
//                 print("✅ 編集結果の保存・読み込み完了")
//             }
//         }
//     }

//     // 背景画像をリセット
//     func resetBackgroundImage() {
//         if let savedData = userDefaultsManager.loadBackgroundImageData(for: userId) {
//             persistenceManager.deleteImageSet(savedData)
//         }
//         userDefaultsManager.deleteBackgroundImageData(for: userId)

//         currentEditedImage = nil
//         currentThumbnail = nil
//         currentOriginalImage = nil
//         currentTransform = ImageTransform()

//         print("🔄 背景画像リセット完了: \(userId)")
//     }

//     // 再編集用の元画像を取得
//     func getOriginalImageForReEdit() -> UIImage? {
//         return currentOriginalImage
//     }

//     // 最終的な表示用画像を取得
//     func getFinalDisplayImage() -> UIImage? {
//         return currentEditedImage
//     }

//     // サムネイル取得
//     func getThumbnailImage() -> UIImage? {
//         return currentThumbnail
//     }
// }

// // MARK: - Simple Background Display View
// struct SimpleBackgroundImageView: View {
//     let image: UIImage

//     var body: some View {
//         Image(uiImage: image)
//             .resizable()
//             .aspectRatio(contentMode: .fill)
//             .ignoresSafeArea()
//     }
// }

// // MARK: - Enhanced User Detail View
// struct EnhancedUserDetailView: View {
//     @StateObject private var imageManager: EnhancedBackgroundImageManager
//     @State private var showingImageEditor = false
//     @State private var selectedImage: UIImage?
//     @State private var showingReEditOption = false

//     let userId: String

//     init(userId: String) {
//         self.userId = userId
//         self._imageManager = StateObject(
//             wrappedValue: EnhancedBackgroundImageManager(userId: userId))
//     }

//     var body: some View {
//         GeometryReader { geometry in
//             ZStack {
//                 // 背景画像表示
//                 if imageManager.isLoading {
//                     ProgressView("背景画像を読み込み中...")
//                         .frame(maxWidth: .infinity, maxHeight: .infinity)
//                         .background(Color.black.opacity(0.1))
//                         .ignoresSafeArea()
//                 } else if let editedImage = imageManager.getFinalDisplayImage() {
//                     // 編集済み画像をそのまま表示（変換処理不要）
//                     SimpleBackgroundImageView(image: editedImage)
//                 } else {
//                     LinearGradient(
//                         colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
//                         startPoint: .topLeading,
//                         endPoint: .bottomTrailing
//                     )
//                     .ignoresSafeArea()
//                 }

//                 // 保存中のオーバーレイ
//                 if imageManager.isSaving {
//                     ZStack {
//                         Color.black.opacity(0.5)
//                             .ignoresSafeArea()

//                         VStack {
//                             ProgressView()
//                                 .scaleEffect(1.5)
//                             Text("編集結果を保存中...")
//                                 .foregroundColor(.white)
//                                 .padding(.top)
//                         }
//                     }
//                 }

//                 // オーバーレイ
//                 Color.black.opacity(0.3)
//                     .ignoresSafeArea()

//                 VStack(spacing: 20) {
//                     Spacer()

//                     // プロフィール画像
//                     Circle()
//                         .fill(Color.white)
//                         .frame(width: 120, height: 120)
//                         .overlay(
//                             Image(systemName: "person.fill")
//                                 .font(.system(size: 50))
//                                 .foregroundColor(.gray)
//                         )

//                     // ユーザー名
//                     Text("ユーザー: \(userId)")
//                         .font(.title)
//                         .fontWeight(.bold)
//                         .foregroundColor(.white)

//                     // 説明
//                     Text("編集済み画像として保存・表示")
//                         .font(.body)
//                         .foregroundColor(.white.opacity(0.8))
//                         .multilineTextAlignment(.center)
//                         .padding(.horizontal)

//                     Spacer()

//                     // 操作ボタン
//                     VStack(spacing: 12) {
//                         // 新しい画像を選択
//                         PhotoPickerView { image in
//                             print("🎯 UserDetailView: PhotoPickerからコールバック受信 - 画像サイズ: \(image.size)")
//                             selectedImage = image
//                             imageManager.setOriginalImage(image)
//                             print("🎯 UserDetailView: 編集画面を表示します")
//                             showingImageEditor = true
//                         }
//                         .background(
//                             RoundedRectangle(cornerRadius: 10)
//                                 .fill(Color.white.opacity(0.9))
//                         )

//                         // 再編集ボタン
//                         if imageManager.getOriginalImageForReEdit() != nil {
//                             Button("現在の画像を再編集") {
//                                 if let originalImage = imageManager.getOriginalImageForReEdit() {
//                                     selectedImage = originalImage
//                                     showingImageEditor = true
//                                 }
//                             }
//                             .foregroundColor(.blue)
//                             .padding()
//                             .background(
//                                 RoundedRectangle(cornerRadius: 10)
//                                     .fill(Color.white.opacity(0.9))
//                             )
//                         }

//                         // リセットボタン
//                         if imageManager.getFinalDisplayImage() != nil {
//                             Button("背景画像をリセット") {
//                                 imageManager.resetBackgroundImage()
//                             }
//                             .foregroundColor(.red)
//                             .padding()
//                             .background(
//                                 RoundedRectangle(cornerRadius: 10)
//                                     .fill(Color.white.opacity(0.9))
//                             )
//                         }
//                     }

//                     // デバッグ情報
//                     if let editedImage = imageManager.getFinalDisplayImage() {
//                         VStack(alignment: .leading, spacing: 4) {
//                             Text("保存済み画像情報:")
//                                 .font(.caption)
//                                 .foregroundColor(.white)
//                             Text(
//                                 "編集済みサイズ: \(Int(editedImage.size.width))×\(Int(editedImage.size.height))"
//                             )
//                             .font(.caption)
//                             .foregroundColor(.white.opacity(0.7))
//                             if let thumbnail = imageManager.getThumbnailImage() {
//                                 Text(
//                                     "サムネイルサイズ: \(Int(thumbnail.size.width))×\(Int(thumbnail.size.height))"
//                                 )
//                                 .font(.caption)
//                                 .foregroundColor(.white.opacity(0.7))
//                             }
//                         }
//                         .padding()
//                         .background(Color.black.opacity(0.5))
//                         .cornerRadius(8)
//                     }

//                     Spacer()
//                 }
//                 .padding()
//             }
//         }
//         .fullScreenCover(isPresented: $showingImageEditor) {

//             if let image = selectedImage {

//                 ImageEditView(
//                     image: image,
//                     initialTransform: imageManager.currentTransform,
//                     onComplete: { transform in
//                         print("✅ UserDetailView: 編集完了コールバック")
//                         imageManager.saveEditedResult(transform)
//                         showingImageEditor = false
//                         selectedImage = nil
//                     },
//                     onCancel: {
//                         print("❌ UserDetailView: 編集キャンセル")
//                         showingImageEditor = false
//                         selectedImage = nil
//                     }
//                 )
//             } else {
//                 // デバッグ用：画像がない場合の表示
//                 VStack {
//                     Text("画像が見つかりません")
//                         .foregroundColor(.red)
//                     Button("閉じる") {
//                         showingImageEditor = false
//                     }
//                 }
//                 .onAppear {
//                     print("❌ UserDetailView: 編集画面で画像がnil")
//                 }
//             }
//         }
//         .navigationBarTitleDisplayMode(.inline)
//         .navigationTitle("ユーザー詳細（改善版）")
//     }
// }

// // MARK: - Enhanced Image Edit View
// struct ImageEditView: View {
//     @State private var transform: ImageTransform
//     @State private var lastScale: CGFloat = 1.0
//     @State private var lastOffset: CGPoint = .zero

//     let image: UIImage
//     let onComplete: (ImageTransform) -> Void
//     let onCancel: () -> Void

//     init(
//         image: UIImage, initialTransform: ImageTransform = ImageTransform(),
//         onComplete: @escaping (ImageTransform) -> Void, onCancel: @escaping () -> Void
//     ) {
//         self.image = image
//         self._transform = State(initialValue: initialTransform)
//         self._lastScale = State(initialValue: initialTransform.scale)
//         self._lastOffset = State(initialValue: initialTransform.normalizedOffset)
//         self.onComplete = onComplete
//         self.onCancel = onCancel
//     }

//     var body: some View {
//         NavigationView {
//             GeometryReader { geometry in
//                 ZStack {
//                     Color.black.ignoresSafeArea()

//                     Image(uiImage: image)
//                         .resizable()
//                         .aspectRatio(contentMode: .fit)
//                         .scaleEffect(transform.scale)
//                         .offset(
//                             x: transform.actualOffset(for: geometry.size).width,
//                             y: transform.actualOffset(for: geometry.size).height
//                         )
//                         .gesture(
//                             SimultaneousGesture(
//                                 MagnificationGesture()
//                                     .onChanged { value in
//                                         transform.scale = lastScale * value
//                                     }
//                                     .onEnded { value in
//                                         lastScale = transform.scale
//                                         if transform.scale < 0.5 {
//                                             transform.scale = 0.5
//                                             lastScale = 0.5
//                                         } else if transform.scale > 3.0 {
//                                             transform.scale = 3.0
//                                             lastScale = 3.0
//                                         }
//                                     },

//                                 DragGesture()
//                                     .onChanged { value in
//                                         let newOffsetX =
//                                             lastOffset.x
//                                             + (value.translation.width / geometry.size.width * 2)
//                                         let newOffsetY =
//                                             lastOffset.y
//                                             + (value.translation.height / geometry.size.height * 2)

//                                         transform.normalizedOffset = CGPoint(
//                                             x: max(-1.0, min(1.0, newOffsetX)),
//                                             y: max(-1.0, min(1.0, newOffsetY))
//                                         )
//                                     }
//                                     .onEnded { _ in
//                                         lastOffset = transform.normalizedOffset
//                                     }
//                             )
//                         )
//                 }
//             }
//             .navigationBarTitleDisplayMode(.inline)
//             .navigationTitle("画像を編集")
//             .toolbar {
//                 ToolbarItem(placement: .navigationBarLeading) {
//                     Button("キャンセル") {
//                         onCancel()
//                     }
//                 }

//                 ToolbarItem(placement: .navigationBarTrailing) {
//                     Button("決定") {
//                         onComplete(transform)
//                     }
//                     .fontWeight(.semibold)
//                 }
//             }
//         }
//     }
// }

// // MARK: - Photo Permission Manager
// class PhotoPermissionManager: ObservableObject {
//     @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

//     init() {
//         checkPermission()
//     }

//     func checkPermission() {
//         authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
//     }

//     func requestPermission() {
//         PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
//             DispatchQueue.main.async {
//                 self?.authorizationStatus = status
//             }
//         }
//     }
// }

// // MARK: - Enhanced Photo Picker View
// struct PhotoPickerView: View {
//     @StateObject private var permissionManager = PhotoPermissionManager()
//     @State private var selectedItem: PhotosPickerItem?
//     @State private var isProcessing = false
//     @State private var showingPermissionAlert = false

//     let onImageSelected: (UIImage) -> Void

//     var body: some View {
//         Group {
//             if permissionManager.authorizationStatus == .authorized
//                 || permissionManager.authorizationStatus == .limited
//             {
//                 PhotosPicker(
//                     selection: $selectedItem,
//                     matching: .images,
//                     photoLibrary: .shared()
//                 ) {
//                     HStack {
//                         if isProcessing {
//                             ProgressView()
//                                 .scaleEffect(0.8)
//                         } else {
//                             Image(systemName: "photo")
//                         }
//                         Text(isProcessing ? "処理中..." : "画像を変更")
//                     }
//                     .foregroundColor(.blue)
//                     .padding()
//                 }
//                 .disabled(isProcessing)
//             } else {
//                 Button(action: {
//                     if permissionManager.authorizationStatus == .denied {
//                         showingPermissionAlert = true
//                     } else {
//                         permissionManager.requestPermission()
//                     }
//                 }) {
//                     HStack {
//                         Image(systemName: "photo")
//                         Text("写真ライブラリにアクセス")
//                     }
//                     .foregroundColor(.blue)
//                     .padding()
//                 }
//             }
//         }
//         .onChange(of: selectedItem) { oldItem, newItem in
//             print("📸 PhotoPicker: 選択アイテム変更 - 新しいアイテム: \(newItem != nil)")

//             guard let newItem = newItem else {
//                 print("❌ PhotoPicker: 選択アイテムがnil")
//                 return
//             }

//             isProcessing = true

//             Task {
//                 do {
//                     print("🔄 PhotoPicker: 画像データ読み込み開始")

//                     // まずData型で試す
//                     if let data = try? await newItem.loadTransferable(type: Data.self) {
//                         print("✅ PhotoPicker: Data読み込み成功 - サイズ: \(data.count) bytes")

//                         if let uiImage = UIImage(data: data) {
//                             print("✅ PhotoPicker: UIImage変換成功 - サイズ: \(uiImage.size)")

//                             await MainActor.run {
//                                 isProcessing = false
//                                 onImageSelected(uiImage)
//                                 selectedItem = nil  // 選択をリセット
//                                 print("✅ PhotoPicker: コールバック実行完了")
//                             }
//                         } else {
//                             print("❌ PhotoPicker: UIImageへの変換に失敗")
//                             await MainActor.run {
//                                 isProcessing = false
//                             }
//                         }
//                     } else {
//                         print("❌ PhotoPicker: データ読み込みに失敗")

//                         // Image型で試す（フォールバック）
//                         if let image = try? await newItem.loadTransferable(type: Image.self) {
//                             print("ℹ️ PhotoPicker: Image型での読み込みは成功（UIImageへの変換が必要）")
//                         }

//                         await MainActor.run {
//                             isProcessing = false
//                         }
//                     }
//                 } catch {
//                     print("❌ PhotoPicker: 読み込みエラー - \(error)")
//                     await MainActor.run {
//                         isProcessing = false
//                     }
//                 }
//             }
//         }
//         .alert("写真ライブラリへのアクセス", isPresented: $showingPermissionAlert) {
//             Button("設定を開く") {
//                 if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
//                     UIApplication.shared.open(settingsUrl)
//                 }
//             }
//             Button("キャンセル", role: .cancel) {}
//         } message: {
//             Text("写真を選択するには、設定で写真ライブラリへのアクセスを許可してください。")
//         }
//         .onAppear {
//             permissionManager.checkPermission()
//         }
//     }
// }

// // MARK: - Required Extensions and Structs
// struct ImageTransform: Codable {
//     var scale: CGFloat = 1.0
//     var normalizedOffset: CGPoint = .zero

//     func actualOffset(for size: CGSize) -> CGSize {
//         CGSize(
//             width: normalizedOffset.x * size.width / 2,
//             height: normalizedOffset.y * size.height / 2)
//     }
// }

// extension CGPoint: Codable {}
// extension CGSize: Codable {}

// extension FileManager {
//     static var documentsDirectory: URL {
//         FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//     }

//     static var backgroundImagesDirectory: URL {
//         documentsDirectory.appendingPathComponent("BackgroundImages", isDirectory: true)
//     }

//     static func ensureBackgroundImagesDirectory() {
//         let url = backgroundImagesDirectory
//         if !FileManager.default.fileExists(atPath: url.path) {
//             try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
//         }
//     }
// }

// extension UIImage {
//     func downsample(to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
//         guard let data = self.jpegData(compressionQuality: 0.9) else { return nil }

//         let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
//         guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions)
//         else {
//             return nil
//         }

//         let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
//         let downsampleOptions =
//             [
//                 kCGImageSourceCreateThumbnailFromImageAlways: true,
//                 kCGImageSourceShouldCacheImmediately: true,
//                 kCGImageSourceCreateThumbnailWithTransform: true,
//                 kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels,
//             ] as CFDictionary

//         guard
//             let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
//                 imageSource, 0, downsampleOptions)
//         else {
//             return nil
//         }

//         return UIImage(cgImage: downsampledImage)
//     }
// }

// // MARK: - Enhanced User Detail View
// struct UserDetailView: View {
//     @StateObject private var imageManager: EnhancedBackgroundImageManager
//     @State private var showingImageEditor = false
//     @State private var selectedImage: UIImage?

//     let userId: String

//     init(userId: String) {
//         self.userId = userId
//         self._imageManager = StateObject(wrappedValue: EnhancedBackgroundImageManager(userId: userId))
//     }

//     var body: some View {
//         GeometryReader { geometry in
//             ZStack {
//                 // 背景画像または読み込み中
//                 if imageManager.isLoading {
//                     ProgressView("背景画像を読み込み中...")
//                         .frame(maxWidth: .infinity, maxHeight: .infinity)
//                         .background(Color.black.opacity(0.1))
//                         .ignoresSafeArea()
//                 } else if let image = imageManager.getFinalDisplayImage() {
//                     SimpleBackgroundImageView(image: image)
//                         .ignoresSafeArea()
//                 } else {
//                     LinearGradient(
//                         colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
//                         startPoint: .topLeading,
//                         endPoint: .bottomTrailing
//                     )
//                     .ignoresSafeArea()
//                 }

//                 // オーバーレイ
//                 Color.black.opacity(0.3)
//                     .ignoresSafeArea()

//                 VStack(spacing: 20) {
//                     Spacer()

//                     // プロフィール画像
//                     Circle()
//                         .fill(Color.white)
//                         .frame(width: 120, height: 120)
//                         .overlay(
//                             Image(systemName: "person.fill")
//                                 .font(.system(size: 50))
//                                 .foregroundColor(.gray)
//                         )

//                     // ユーザー名
//                     Text("ユーザー: \(userId)")
//                         .font(.title)
//                         .fontWeight(.bold)
//                         .foregroundColor(.white)

//                     // 説明
//                     Text("永続化された背景画像が表示されます")
//                         .font(.body)
//                         .foregroundColor(.white.opacity(0.8))
//                         .multilineTextAlignment(.center)
//                         .padding(.horizontal)

//                     Spacer()

//                     // 操作ボタン
//                     VStack(spacing: 12) {
//                         // 画像変更ボタン
//                         PhotoPickerView { image in
//                             selectedImage = image
//                             imageManager.setOriginalImage(image)
//                             showingImageEditor = true
//                         }
//                         .background(
//                             RoundedRectangle(cornerRadius: 10)
//                                 .fill(Color.white.opacity(0.9))
//                         )

//                         // リセットボタン
//                         if imageManager.getFinalDisplayImage() != nil {
//                             Button("背景画像をリセット") {
//                                 imageManager.resetBackgroundImage()
//                             }
//                             .foregroundColor(.red)
//                             .padding()
//                             .background(
//                                 RoundedRectangle(cornerRadius: 10)
//                                     .fill(Color.white.opacity(0.9))
//                             )
//                         }
//                     }

//                     // デバッグ情報
//                     if imageManager.getFinalDisplayImage() != nil {
//                         VStack(alignment: .leading, spacing: 4) {
//                             Text("永続化情報:")
//                                 .font(.caption)
//                                 .foregroundColor(.white)
//                             Text(
//                                 "Scale: \(String(format: "%.2f", imageManager.currentTransform.scale))"
//                             )
//                             .font(.caption)
//                             .foregroundColor(.white.opacity(0.7))
//                             Text(
//                                 "Offset: (\(String(format: "%.2f", imageManager.currentTransform.normalizedOffset.x)), \(String(format: "%.2f", imageManager.currentTransform.normalizedOffset.y)))"
//                             )
//                             .font(.caption)
//                             .foregroundColor(.white.opacity(0.7))
//                         }
//                         .padding()
//                         .background(Color.black.opacity(0.5))
//                         .cornerRadius(8)
//                     }

//                     Spacer()
//                 }
//                 .padding()
//             }
//         }
//         .fullScreenCover(isPresented: $showingImageEditor) {
//             if let image = selectedImage {
//                 ImageEditView(
//                     image: image,
//                     initialTransform: imageManager.currentTransform,
//                     onComplete: { transform in
//                         imageManager.saveEditedResult(transform)
//                         showingImageEditor = false
//                         selectedImage = nil
//                     },
//                     onCancel: {
//                         showingImageEditor = false
//                         selectedImage = nil
//                     }
//                 )
//             }
//         }
//         .navigationBarTitleDisplayMode(.inline)
//         .navigationTitle("ユーザー詳細")
//     }
// }

// // MARK: - Usage Example
// struct ContentView: View {
//     var body: some View {
//         NavigationView {
//             VStack(spacing: 20) {
//                 Text("背景画像永続化デモ")
//                     .font(.title)
//                     .fontWeight(.bold)

//                 NavigationLink("ユーザー1の詳細", destination: UserDetailView(userId: "user1"))
//                 NavigationLink("ユーザー2の詳細", destination: UserDetailView(userId: "user2"))
//                 NavigationLink("ユーザー3の詳細", destination: UserDetailView(userId: "user3"))
//             }
//             .padding()
//         }
//     }
// }

// // MARK: - Preview
// struct ContentView_Previews: PreviewProvider {
//     static var previews: some View {
//         ContentView()
//     }
// }

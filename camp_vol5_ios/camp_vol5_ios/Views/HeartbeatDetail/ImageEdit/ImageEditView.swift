// Views/HeartbeatDetail/ImageEdit/ImageEditView.swift
// 画像編集画面のメインコンテナ - MVVMアーキテクチャに従い、
// 子コンポーネントに責任を分離したモジュラー構成にリファクタリング

import PhotosUI
import SwiftUI

struct ImageEditView: View {
    // MARK: - Bindings

    @Binding var image: UIImage?
    @Binding var imageOffset: CGSize
    @Binding var imageScale: CGFloat
    @Binding var imageRotation: Double
    @Binding var heartOffset: CGSize
    @Binding var heartSize: CGFloat

    // MARK: - Properties

    let onApply: () -> Void
    let userId: String

    // MARK: - State

    @State private var tempOffset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var tempScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var tempRotation: Double = 0.0
    @State private var lastRotation: Double = 0.0
    @State private var tempHeartOffset = CGSize.zero
    @State private var lastHeartOffset = CGSize.zero
    @State private var tempHeartSize: CGFloat = 105.0
    @State private var showingPhotoPicker = false
    @State private var showingHeartSizeSlider = false
    @State private var selectedBackgroundColor: Color = .clear
    @State private var tempColor: Color = .clear
    @State private var imageData: Data?
    @State private var isAnimatedImage: Bool = false

    // MARK: - Environment

    @Environment(\.presentationMode) var presentationMode

    // MARK: - Dependencies

    private let persistenceManager = PersistenceManager.shared

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                backgroundView

                // 画像表示とジェスチャー
                ImageGestureHandlerView(
                    image: image,
                    imageData: imageData,
                    isAnimatedImage: isAnimatedImage,
                    tempOffset: $tempOffset,
                    lastOffset: $lastOffset,
                    tempScale: $tempScale,
                    lastScale: $lastScale,
                    tempRotation: $tempRotation,
                    lastRotation: $lastRotation
                )

                // コントロールボタン
                ImageControlButtonsView(
                    showingPhotoPicker: $showingPhotoPicker,
                    showingHeartSizeSlider: $showingHeartSizeSlider,
                    selectedBackgroundColor: $selectedBackgroundColor,
                    isImageSelected: image != nil,
                    onResetPosition: resetImagePosition
                )
            }
            .overlay(
                // ハート位置編集
                HeartPositionEditorView(
                    tempHeartOffset: $tempHeartOffset,
                    lastHeartOffset: $lastHeartOffset,
                    tempHeartSize: $tempHeartSize,
                    showingHeartSizeSlider: $showingHeartSizeSlider,
                    isImageSelected: image != nil
                ),
                alignment: .center
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackgroundTransparent()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }

                ToolbarItem(placement: .principal) {
                    WhiteCapsuleTitle(title: "画像を編集中")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("適用") {
                        applyChanges()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .disabled(image == nil)
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            GifPhotoPickerView(selectedImage: $image, selectedImageData: $imageData)
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: selectedBackgroundColor) { _, newColor in
            tempColor = newColor
        }
        .onChange(of: imageData) { _, newData in
            updateAnimatedImageState(newData)
        }
    }

    // MARK: - Subviews

    /// 背景ビュー
    private var backgroundView: some View {
        Group {
            if selectedBackgroundColor != Color.clear {
                selectedBackgroundColor
                    .ignoresSafeArea()
            } else {
                MainAccentGradient()
            }
        }
    }

    // MARK: - Actions

    /// 変更を適用して保存
    private func applyChanges() {
        // 編集内容を適用
        imageOffset = tempOffset
        imageScale = tempScale
        imageRotation = tempRotation
        heartOffset = tempHeartOffset
        heartSize = tempHeartSize

        // 各種データを永続化
        persistenceManager.saveHeartPosition(tempHeartOffset, userId: userId)
        persistenceManager.saveHeartSize(tempHeartSize, userId: userId)
        persistenceManager.saveImageTransform(
            offset: tempOffset,
            scale: tempScale,
            rotation: tempRotation,
            userId: userId
        )
        persistenceManager.saveBackgroundColor(tempColor, userId: userId)

        // 画像データを保存（GIF対応）
        if let image = image {
            persistenceManager.saveBackgroundImage(
                image,
                userId: userId,
                imageData: imageData
            )
        }

        onApply()
    }

    /// 画像とハートの位置をリセット
    private func resetImagePosition() {
        withAnimation(.spring()) {
            tempOffset = .zero
            lastOffset = .zero
            tempScale = 1.0
            lastScale = 1.0
            tempRotation = 0.0
            lastRotation = 0.0
            tempHeartOffset = .zero
            lastHeartOffset = .zero
        }
    }

    // MARK: - Setup

    /// 初期状態をセットアップ
    private func setupInitialState() {
        // 背景色を読み込み
        selectedBackgroundColor = persistenceManager.loadBackgroundColor(userId: userId)

        // アニメーション画像かどうかを確認
        isAnimatedImage = persistenceManager.isAnimatedImage(userId: userId)

        // 画像データを読み込み（GIF対応）
        if image != nil, isAnimatedImage {
            if let data = persistenceManager.loadBackgroundImageData(userId: userId) {
                imageData = data
            }
        } else {
            imageData = nil
        }

        // Bindingから渡された値を使用
        tempOffset = imageOffset
        lastOffset = imageOffset
        tempScale = imageScale
        lastScale = imageScale
        tempRotation = imageRotation
        lastRotation = imageRotation

        // ハートの位置とサイズをtempに初期化
        tempHeartOffset = heartOffset
        lastHeartOffset = heartOffset
        tempHeartSize = heartSize
    }

    /// アニメーション画像の状態を更新
    private func updateAnimatedImageState(_ newData: Data?) {
        if let data = newData, data.count > 3 {
            // GIFのマジックナンバーをチェック（"GIF"）
            let header = [UInt8](data.prefix(3))
            isAnimatedImage = (header == [0x47, 0x49, 0x46])
        } else {
            isAnimatedImage = false
        }
    }
}

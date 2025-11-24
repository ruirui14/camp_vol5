// Views/HeartbeatDetailView.swift
// 心拍詳細画面 - MVVMアーキテクチャとSwiftUIベストプラクティスに従い、
// 責任を分離したコンポーネント構成でリファクタリング

import PhotosUI
import SwiftUI
import UIKit

struct ImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct HeartbeatDetailView: View {
    // MARK: - ViewModels & Services
    @StateObject private var viewModel: HeartbeatDetailViewModel

    // MARK: - Environment & Presentation
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModelFactory: ViewModelFactory
    @Binding private var isStatusBarHidden: Bool
    @Binding private var isPersistentSystemOverlaysHidden: Visibility

    // MARK: - UI State
    @State private var selectedImage: UIImage?
    @State private var editedImage: UIImage?
    @State private var showingImageEditor = false
    @State private var showingCardBackgroundEditSheet = false
    @State private var showingStreamView = false
    @State private var imageOffset = CGSize.zero
    @State private var imageScale: CGFloat = 1.0
    @State private var imageRotation: Double = 0.0
    @State private var heartOffset = CGSize.zero
    @State private var heartSize: CGFloat = 105.0
    @State private var savedBackgroundColor: Color = .clear
    @State private var backgroundImageData: Data?
    @State private var isAnimatedBackground: Bool = false
    @State private var streamViewModel: StreamViewModel?

    // MARK: - Dependencies
    private let persistenceManager = PersistenceManager.shared
    @StateObject private var backgroundImageManager: BackgroundImageManager
    private let userIdParams: String

    init(
        userId: String,
        isStatusBarHidden: Binding<Bool> = .constant(false),
        isPersistentSystemOverlaysHidden: Binding<Visibility> = .constant(.automatic)
    ) {
        self.userIdParams = userId
        _viewModel = StateObject(wrappedValue: HeartbeatDetailViewModel(userId: userId))
        _backgroundImageManager = StateObject(wrappedValue: BackgroundImageManager(userId: userId))
        _isStatusBarHidden = isStatusBarHidden
        _isPersistentSystemOverlaysHidden = isPersistentSystemOverlaysHidden
    }

    init(
        userWithHeartbeat: UserWithHeartbeat,
        isStatusBarHidden: Binding<Bool> = .constant(false),
        isPersistentSystemOverlaysHidden: Binding<Visibility> = .constant(.automatic)
    ) {
        self.userIdParams = userWithHeartbeat.user.id
        _viewModel = StateObject(
            wrappedValue: HeartbeatDetailViewModel(userId: userWithHeartbeat.user.id)
        )
        _backgroundImageManager = StateObject(
            wrappedValue: BackgroundImageManager(userId: userWithHeartbeat.user.id)
        )
        _isStatusBarHidden = isStatusBarHidden
        _isPersistentSystemOverlaysHidden = isPersistentSystemOverlaysHidden
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // 背景コンポーネント（GIF対応）
                HeartbeatDetailBackground(
                    backgroundImage: editedImage ?? selectedImage,
                    backgroundImageData: backgroundImageData,
                    backgroundColor: savedBackgroundColor,
                    imageOffset: imageOffset,
                    imageScale: imageScale,
                    imageRotation: imageRotation,
                    isAnimated: isAnimatedBackground
                )

                // メインコンテンツ
                VStack(spacing: 20) {
                    Spacer()
                    Spacer()
                    Spacer()

                    // ステータス表示コンポーネント
                    HeartbeatDetailStatusBar(
                        isVibrationEnabled: viewModel.isVibrationEnabled,
                        isVibrating: viewModel.isVibrating,
                        vibrationStatus: viewModel.vibrationStatus,
                        autoLockDisabled: viewModel.autoLockManager.autoLockDisabled,
                        remainingTime: viewModel.autoLockManager.remainingTime,
                        isSleepMode: viewModel.isSleepMode,
                        heartbeat: viewModel.currentHeartbeat
                    )

                    // エラーメッセージ
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }

                    Spacer()
                }
                .padding()
                .padding(.top, 118)

                // ハートアニメーション
                HeartAnimationView(
                    bpm: viewModel.currentHeartbeat?.bpm ?? 0,
                    heartSize: heartSize,
                    showBPM: true,
                    enableHaptic: false,
                    heartColor: .red,
                    syncWithVibration: viewModel.isVibrationEnabled
                )
                .offset(heartOffset)
                .ignoresSafeArea()
            }
        }
        .overlay {
            if viewModel.isSleepMode {
                Color.black
                    .ignoresSafeArea(.all, edges: .all)
                    .onTapGesture {
                        viewModel.toggleSleepMode()
                        updateSystemUIVisibility()
                    }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarBackgroundTransparent()
        .if(!viewModel.isSleepMode) { view in
            view.toolbar {
                HeartbeatDetailToolbar(
                    userName: viewModel.user?.name ?? "",
                    isVibrationEnabled: viewModel.isVibrationEnabled,
                    onDismiss: {
                        presentationMode.wrappedValue.dismiss()
                    },
                    onToggleSleep: {
                        viewModel.toggleSleepMode()
                        updateSystemUIVisibility()
                    },
                    onToggleVibration: {
                        viewModel.toggleVibration()
                    },
                    onOpenStream: {
                        // StreamViewModelを一度だけ作成して保持
                        // HeartbeatDetailViewModelの心拍データを共有する
                        if streamViewModel == nil {
                            streamViewModel = viewModelFactory.makeStreamViewModel(
                                heartbeatDetailViewModel: viewModel)
                        }
                        showingStreamView = true
                    },
                    onEditCardBackground: {
                        viewModel.stopVibration()
                        showingCardBackgroundEditSheet = true
                    },
                    onEditBackgroundImage: {
                        viewModel.stopVibration()
                        showingImageEditor = true
                    },
                    onResetBackgroundImage: {
                        resetBackgroundImage()
                    },
                    hasBackgroundImage: selectedImage != nil
                )
            }
        }
        .onAppear {
            setupView()
        }
        .onDisappear {
            teardownView()
        }
        .onChange(of: viewModel.isSleepMode) {
            updateSystemUIVisibility()
        }
        .onChange(of: viewModel.orientationManager.isFaceDown) { _, isFaceDown in
            handleOrientationChange(isFaceDown: isFaceDown)
        }
        .fullScreenCover(
            isPresented: $showingImageEditor,
        ) {
            ImageEditView(
                image: $selectedImage,
                imageOffset: $imageOffset,
                imageScale: $imageScale,
                imageRotation: $imageRotation,
                heartOffset: $heartOffset,
                heartSize: $heartSize,
                onApply: {
                    showingImageEditor = false
                },
                userId: userIdParams
            )
        }
        .fullScreenCover(
            isPresented: $showingCardBackgroundEditSheet,
            onDismiss: {
                refreshPersistedData()
            }
        ) {
            CardBackgroundEditView(userId: userIdParams)
        }
        .navigationDestination(isPresented: $showingStreamView) {
            if let streamViewModel = streamViewModel {
                StreamView(
                    viewModel: streamViewModel,
                    userName: viewModel.user?.name ?? ""
                )
            }
        }
    }

    private func loadPersistedData() {
        // 保存された画像を読み込み（ユーザーID別、GIF対応）
        if let savedImage = persistenceManager.loadBackgroundImage(userId: userIdParams) {
            selectedImage = savedImage
            editedImage = savedImage
        }

        // GIF画像データを読み込み
        if let savedImageData = persistenceManager.loadBackgroundImageData(userId: userIdParams) {
            backgroundImageData = savedImageData
            isAnimatedBackground = persistenceManager.isAnimatedImage(userId: userIdParams)
        }

        // 保存された変形情報を読み込み（ユーザーID別）
        let transform = persistenceManager.loadImageTransform(userId: userIdParams)
        imageOffset = transform.offset
        imageScale = transform.scale
        imageRotation = transform.rotation

        // ハートの位置を読み込み
        let heartPosition = persistenceManager.loadHeartPosition(userId: userIdParams)
        heartOffset = heartPosition

        // ハートのサイズを読み込み
        heartSize = persistenceManager.loadHeartSize(userId: userIdParams)
    }

    // MARK: - Private Methods

    private func setupView() {
        viewModel.startMonitoring()
        loadPersistedData()
        loadSavedBackgroundColor()
        setupAutoLock()
        viewModel.orientationManager.startMonitoring()
    }

    private func teardownView() {
        // StreamViewが表示されている場合は監視を継続
        // （StreamViewがHeartbeatDetailViewModelのデータを使用しているため）
        if !showingStreamView {
            viewModel.stopMonitoring()
        }
        viewModel.autoLockManager.disableAutoLockDisabling()
        viewModel.orientationManager.stopMonitoring()
    }

    private func updateSystemUIVisibility() {
        isStatusBarHidden = viewModel.isSleepMode
        isPersistentSystemOverlaysHidden = viewModel.isSleepMode ? .hidden : .automatic
    }

    private func loadSavedBackgroundColor() {
        savedBackgroundColor = persistenceManager.loadBackgroundColor(userId: userIdParams)
    }

    private func setupAutoLock() {
        if viewModel.autoLockManager.autoLockDisabled {
            viewModel.autoLockManager.enableAutoLockDisabling()
        }
    }

    private func resetBackgroundImage() {
        // BackgroundImageManagerの状態をリセット（新システム）
        backgroundImageManager.resetBackgroundImage()

        // PersistenceManagerのデータもクリア（旧システム - ユーザーID別）
        persistenceManager.clearAllData(userId: userIdParams)

        // ローカルUIの状態をリセット
        selectedImage = nil
        editedImage = nil
        backgroundImageData = nil
        isAnimatedBackground = false
        imageOffset = CGSize.zero
        imageScale = 1.0
        imageRotation = 0.0

        // ハートの位置とサイズをリセット
        heartOffset = CGSize.zero
        heartSize = 105.0
    }

    private func handleOrientationChange(isFaceDown: Bool) {
        // 自動スリープが有効で、まだスリープモードでない場合のみ自動でスリープモードに移行
        if isFaceDown && viewModel.orientationManager.autoSleepEnabled && !viewModel.isSleepMode {
            viewModel.toggleSleepMode()
            updateSystemUIVisibility()
        }
    }

    private func refreshPersistedData() {
        // 保存された画像を再読み込み（ユーザーID別、GIF対応）
        if let savedImage = persistenceManager.loadBackgroundImage(userId: userIdParams) {
            selectedImage = savedImage
            editedImage = savedImage
        }

        // GIF画像データを再読み込み
        if let savedImageData = persistenceManager.loadBackgroundImageData(userId: userIdParams) {
            backgroundImageData = savedImageData
            isAnimatedBackground = persistenceManager.isAnimatedImage(userId: userIdParams)
        }

        // 変形情報を再読み込み
        let transform = persistenceManager.loadImageTransform(userId: userIdParams)

        imageOffset = transform.offset
        imageScale = transform.scale
        imageRotation = transform.rotation

        // ハートの位置とサイズを再読み込み
        let heartPosition = persistenceManager.loadHeartPosition(userId: userIdParams)
        heartOffset = heartPosition
        heartSize = persistenceManager.loadHeartSize(userId: userIdParams)

        // 背景色の更新
        savedBackgroundColor = persistenceManager.loadBackgroundColor(userId: userIdParams)

        // 振動を再開
        if viewModel.isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
            if viewModel.isValidBPM(heartbeat.bpm) {
                viewModel.startHeartbeatVibration(bpm: heartbeat.bpm)
            }
        }
    }
}

// SwiftUI条件付きモディファイア用のextension
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

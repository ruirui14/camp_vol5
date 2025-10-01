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
    @ObservedObject private var vibrationService = VibrationService.shared
    @StateObject private var autoLockManager = AutoLockManager.shared

    // MARK: - Environment & Presentation
    @Environment(\.presentationMode) var presentationMode
    @Binding private var isStatusBarHidden: Bool
    @Binding private var isPersistentSystemOverlaysHidden: Visibility

    // MARK: - UI State
    @State private var selectedImage: UIImage?
    @State private var editedImage: UIImage?
    @State private var showingImageEditor = false
    @State private var showingCardBackgroundEditSheet = false
    @State private var imageOffset = CGSize.zero
    @State private var imageScale: CGFloat = 1.0
    @State private var imageRotation: Double = 0.0
    @State private var heartOffset = CGSize.zero
    @State private var heartSize: CGFloat = 105.0
    @State private var savedBackgroundColor: Color = .clear

    // MARK: - Dependencies
    private let persistenceManager = PersistenceManager.shared
    private let userIdParams: String

    init(
        userId: String,
        isStatusBarHidden: Binding<Bool> = .constant(false),
        isPersistentSystemOverlaysHidden: Binding<Visibility> = .constant(.automatic)
    ) {
        self.userIdParams = userId
        _viewModel = StateObject(wrappedValue: HeartbeatDetailViewModel(userId: userId))
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
        _isStatusBarHidden = isStatusBarHidden
        _isPersistentSystemOverlaysHidden = isPersistentSystemOverlaysHidden
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // 背景コンポーネント
                HeartbeatDetailBackground(
                    backgroundImage: editedImage ?? selectedImage,
                    backgroundColor: savedBackgroundColor,
                    imageOffset: imageOffset,
                    imageScale: imageScale,
                    imageRotation: imageRotation
                )

                // メインコンテンツ
                VStack(spacing: 20) {
                    Spacer()
                    Spacer()
                    Spacer()

                    // ステータス表示コンポーネント
                    HeartbeatDetailStatusBar(
                        isVibrationEnabled: viewModel.isVibrationEnabled,
                        isVibrating: vibrationService.isVibrating,
                        vibrationStatus: vibrationService.getVibrationStatus(),
                        autoLockDisabled: autoLockManager.autoLockDisabled,
                        remainingTime: autoLockManager.remainingTime,
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
                    onEditCardBackground: {
                        vibrationService.stopVibration()
                        showingCardBackgroundEditSheet = true
                    },
                    onEditBackgroundImage: {
                        vibrationService.stopVibration()
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
        .onChange(of: viewModel.isSleepMode) { _ in
            updateSystemUIVisibility()
        }
        .fullScreenCover(
            isPresented: $showingImageEditor,
            onDismiss: {
                refreshPersistedData()
            }
        ) {
            ImageEditView(
                image: $selectedImage,
                imageOffset: $imageOffset,
                imageScale: $imageScale,
                imageRotation: $imageRotation,
                onApply: {
                    applyImageChanges()
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
        .fullScreenCover(
            isPresented: $showingImageEditor,
            onDismiss: {
                // ImageEditViewが閉じられたときにハートの位置とサイズを再読み込み（ユーザーID別）
                let heartPosition = persistenceManager.loadHeartPosition(userId: userIdParams)
                heartOffset = heartPosition

                // ハートサイズの更新
                heartSize = persistenceManager.loadHeartSize(userId: userIdParams)

                // 背景色の更新
                savedBackgroundColor = persistenceManager.loadBackgroundColor(userId: userIdParams)

                // 振動を再開（振動が有効で心拍データがある場合）
                if viewModel.isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
                    if vibrationService.isValidBPM(heartbeat.bpm) {
                        vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
                    }
                }
            }
        ) {
            ImageEditView(
                image: $selectedImage,
                imageOffset: $imageOffset,
                imageScale: $imageScale,
                imageRotation: $imageRotation,
                onApply: {
                    print("=== HeartbeatDetailView onApply ===")
                    print("Current user: \(viewModel.user?.name ?? "nil") (ID: \(userIdParams))")

                    editedImage = selectedImage

                    // 画像と変形情報を永続化（ユーザーID別）
                    if let image = selectedImage {
                        print("Saving background image for user: \(userIdParams)")
                        persistenceManager.saveBackgroundImage(image, userId: userIdParams)
                    } else {
                        print("ERROR: Cannot save image - selectedImage: \(selectedImage != nil)")
                    }

                    print("Saving image transform for user: \(userIdParams)")
                    persistenceManager.saveImageTransform(
                        offset: imageOffset, scale: imageScale, rotation: imageRotation,
                        userId: userIdParams)

                    showingImageEditor = false
                    print("=== End HeartbeatDetailView onApply ===")
                },
                userId: userIdParams
            )
        }
        .fullScreenCover(
            isPresented: $showingCardBackgroundEditSheet,
            onDismiss: {
                // CardBackgroundEditViewが閉じられたときもハートサイズを更新（ユーザーID別）
                heartSize = persistenceManager.loadHeartSize(userId: userIdParams)

                // 背景色の更新
                savedBackgroundColor = persistenceManager.loadBackgroundColor(userId: userIdParams)

                // 振動を再開（振動が有効で心拍データがある場合）
                if viewModel.isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
                    if vibrationService.isValidBPM(heartbeat.bpm) {
                        vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
                    }
                }
            }
        ) {
            CardBackgroundEditView(userId: userIdParams)
        }
    }

    private func loadPersistedData() {
        print("=== HeartbeatDetailView loadPersistedData ===")
        print("Current user: \(viewModel.user?.name ?? "nil") (ID: \(userIdParams))")

        // 保存された画像を読み込み（ユーザーID別）
        print("Loading background image for user: \(userIdParams)")
        if let savedImage = persistenceManager.loadBackgroundImage(userId: userIdParams) {
            print("Successfully loaded background image")
            selectedImage = savedImage
            editedImage = savedImage
        } else {
            print("No saved background image found for user: \(userIdParams)")
        }

        // 保存された変形情報を読み込み（ユーザーID別）
        print("Loading transform data for user: \(userIdParams)")
        let transform = persistenceManager.loadImageTransform(userId: userIdParams)
        imageOffset = transform.offset
        imageScale = transform.scale
        imageRotation = transform.rotation

        // ハートの位置を読み込み
        let heartPosition = persistenceManager.loadHeartPosition(userId: userIdParams)
        heartOffset = heartPosition

        // ハートのサイズを読み込み
        heartSize = persistenceManager.loadHeartSize(userId: userIdParams)
        print(
            "Loaded data - offset: \(transform.offset), scale: \(transform.scale), rotation: \(transform.rotation), heartOffset: \(heartPosition), heartSize: \(heartSize)"
        )
        print("=== End loadPersistedData ===")
    }

    // MARK: - Private Methods

    private func setupView() {
        viewModel.startMonitoring()
        loadPersistedData()
        loadSavedBackgroundColor()
        setupAutoLock()
    }

    private func teardownView() {
        viewModel.stopMonitoring()
        autoLockManager.disableAutoLockDisabling()
    }

    private func updateSystemUIVisibility() {
        isStatusBarHidden = viewModel.isSleepMode
        isPersistentSystemOverlaysHidden = viewModel.isSleepMode ? .hidden : .automatic
    }

    private func loadSavedBackgroundColor() {
        print("Loading background color for user: \(userIdParams)")
        savedBackgroundColor = persistenceManager.loadBackgroundColor(userId: userIdParams)
        print("Loaded background color: \(savedBackgroundColor)")
    }

    private func setupAutoLock() {
        if autoLockManager.autoLockDisabled {
            autoLockManager.enableAutoLockDisabling()
        }
    }

    private func resetBackgroundImage() {
        selectedImage = nil
        editedImage = nil
        imageOffset = CGSize.zero
        imageScale = 1.0
        persistenceManager.clearAllData()
    }

    private func refreshPersistedData() {
        // ハートの位置とサイズを再読み込み
        let heartPosition = persistenceManager.loadHeartPosition(userId: userIdParams)
        heartOffset = heartPosition
        heartSize = persistenceManager.loadHeartSize(userId: userIdParams)

        // 背景色の更新
        savedBackgroundColor = persistenceManager.loadBackgroundColor(userId: userIdParams)

        // 振動を再開
        if viewModel.isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
            if vibrationService.isValidBPM(heartbeat.bpm) {
                vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
            }
        }
    }

    private func applyImageChanges() {
        print("=== HeartbeatDetailView onApply ===")
        print("Current user: \(viewModel.user?.name ?? "nil") (ID: \(userIdParams))")

        editedImage = selectedImage

        // 画像と変形情報を永続化
        if let image = selectedImage {
            print("Saving background image for user: \(userIdParams)")
            persistenceManager.saveBackgroundImage(image, userId: userIdParams)
        } else {
            print("ERROR: Cannot save image - selectedImage: \(selectedImage != nil)")
        }

        print("Saving image transform for user: \(userIdParams)")
        persistenceManager.saveImageTransform(
            offset: imageOffset, scale: imageScale, userId: userIdParams)

        showingImageEditor = false
        print("=== End HeartbeatDetailView onApply ===")
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

// Views/HeartbeatDetailView.swift

import PhotosUI
import SwiftUI
import UIKit

struct ImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct HeartbeatDetailView: View {
    @StateObject private var viewModel: HeartbeatDetailViewModel
    @ObservedObject private var vibrationService = VibrationService.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedImage: UIImage?
    @State private var editedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingImageEditor = false
    @State private var imageOffset = CGSize.zero
    @State private var imageScale: CGFloat = 1.0
    @State private var heartOffset = CGSize.zero
    @State private var heartSize: CGFloat = 105.0
    @State private var showingCardBackgroundEditSheet = false
    @State private var isVibrationEnabled = true
    @State private var savedBackgroundColor: Color = .clear
    @State private var isSleepMode = false
    @Binding private var isStatusBarHidden: Bool
    @Binding private var isPersistentSystemOverlaysHidden: Visibility
    @StateObject private var autoLockManager = AutoLockManager.shared

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
                // 常に背景色またはデフォルト背景を表示
                if savedBackgroundColor != Color.clear {
                    // 保存された背景色
                    savedBackgroundColor
                        .ignoresSafeArea()
                } else {
                    // デフォルトのグラデーション背景
                    MainAccentGradient()
                }

                // 背景画像（ある場合のみ上にオーバーレイ）
                if let image = editedImage ?? selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(imageScale)
                        .offset(imageOffset)
                        .ignoresSafeArea()
                }

                VStack(spacing: 20) {
                    // 既存のコンテンツ
                    Spacer()
                    Spacer()
                    Spacer()
                    VStack(spacing: 8) {
                        // 振動状態表示
                        if isVibrationEnabled {
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(vibrationService.isVibrating ? 1.5 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 0.5).repeatForever(),
                                        value: vibrationService.isVibrating
                                    )

                                Text("心拍振動: \(vibrationService.getVibrationStatus())")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                            }
                        }

                        // 自動ロック無効化残り時間
                        if autoLockManager.autoLockDisabled && autoLockManager.remainingTime > 0
                            && !isSleepMode
                        {
                            HStack {
                                Image(systemName: "lock.slash")
                                    .foregroundColor(.yellow)
                                    .font(.caption)

                                Text(
                                    "自動ロック無効: \(formatRemainingTime(autoLockManager.remainingTime))"
                                )
                                .font(.caption)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                            }
                        }

                        if let heartbeat = viewModel.currentHeartbeat {
                            Text(
                                "Last updated: \(heartbeat.timestamp, formatter: dateFormatter)"
                            )
                            .font(.caption)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                        } else {
                            Text("No data available")
                                .font(.caption)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }

                    Spacer()
                }
                .padding()
                .padding(.top, 118)  // NavigationBar分の補正

                // ハートビュー（ImageEditViewと同じ位置）
                heartbeatDisplayView
                    .offset(heartOffset)
                    .ignoresSafeArea()
            }
        }
        .overlay {
            if isSleepMode {
                Color.black
                    .ignoresSafeArea(.all, edges: .all)
                    .onTapGesture {
                        toggleSleepMode()
                    }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        // 透明なナビゲーションバーの設定
        .navigationBarBackgroundTransparent()
        // isSleepModeがfalseの時のみツールバーを表示
        .if(!isSleepMode) { view in
            view.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .principal) {
                    WhiteCapsuleTitle(title: viewModel.user?.name ?? "読み込み中...")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 15) {
                        // 手動スリープボタン
                        Button(action: {
                            toggleSleepMode()
                        }) {
                            Image(systemName: "moon.circle")
                                .foregroundColor(.white)
                                .font(.title3)
                                .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                        }

                        // 振動制御ボタン
                        Button(action: {
                            toggleVibration()
                        }) {
                            Image(
                                systemName: isVibrationEnabled
                                    ? "heart.circle.fill" : "heart.circle"
                            )
                            .foregroundColor(isVibrationEnabled ? .red : .white)
                            .font(.title2)
                            .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                        }

                        Menu {
                            Button("カード背景を編集") {
                                // 編集ページを開く際に振動を停止
                                vibrationService.stopVibration()
                                showingCardBackgroundEditSheet = true
                            }

                            Button("背景画像を編集") {
                                // 編集ページを開く際に振動を停止
                                vibrationService.stopVibration()
                                showingImageEditor = true
                            }

                            if selectedImage != nil {
                                Button("背景画像をリセット", role: .destructive) {
                                    selectedImage = nil
                                    editedImage = nil
                                    imageOffset = CGSize.zero
                                    imageScale = 1.0
                                    persistenceManager.clearAllData()
                                }
                            }
                        } label: {
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.startContinuousMonitoring()
            loadPersistedData()

            // 保存された背景色を読み込み（ユーザーID別）
            print("Loading background color for user: \(userIdParams)")
            savedBackgroundColor = persistenceManager.loadBackgroundColor(userId: userIdParams)
            print("Loaded background color: \(savedBackgroundColor)")

            // 初期状態で振動を有効にし、既にデータがある場合は振動開始
            if isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
                if vibrationService.isValidBPM(heartbeat.bpm) {
                    vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
                }
            }

            // 設定に応じてiOSの自動ロックを制御
            if autoLockManager.autoLockDisabled {
                autoLockManager.enableAutoLockDisabling()
            }
        }
        .onDisappear {
            viewModel.stopMonitoring()
            vibrationService.stopVibration()
            // 自動ロック無効化を解除
            autoLockManager.disableAutoLockDisabling()
        }

        .onChange(of: viewModel.currentHeartbeat) { heartbeat in
            // 心拍データが更新された時の処理

            if isVibrationEnabled {
                if let heartbeat = heartbeat {
                    // 有効なBPMの場合のみ振動を開始
                    if vibrationService.isValidBPM(heartbeat.bpm) {
                        vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
                    } else {
                        vibrationService.stopVibration()
                    }
                } else {
                    vibrationService.stopVibration()
                }
            }
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
                if isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
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
                    persistenceManager.saveImageTransform(offset: imageOffset, scale: imageScale, userId: userIdParams)

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
                if isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
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

        // ハートの位置を読み込み
        let heartPosition = persistenceManager.loadHeartPosition(userId: userIdParams)
        heartOffset = heartPosition

        // ハートのサイズを読み込み
        heartSize = persistenceManager.loadHeartSize(userId: userIdParams)
        print("Loaded data - offset: \(transform.offset), scale: \(transform.scale), heartOffset: \(heartPosition), heartSize: \(heartSize)")
        print("=== End loadPersistedData ===")
    }

    private var heartbeatDisplayView: some View {
        HeartAnimationView(
            bpm: viewModel.currentHeartbeat?.bpm ?? 0,
            heartSize: heartSize,
            showBPM: true,
            enableHaptic: false,  // VibrationServiceと競合しないよう無効
            heartColor: .red,
            syncWithVibration: isVibrationEnabled  // 振動との同期を制御
        )
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    // MARK: - Sleep Mode Control

    private func toggleSleepMode() {
        isSleepMode.toggle()
        isStatusBarHidden = isSleepMode
        isPersistentSystemOverlaysHidden = isSleepMode ? .hidden : .automatic
    }

    // MARK: - Helper Methods

    private func formatRemainingTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Vibration Control

    private func toggleVibration() {
        isVibrationEnabled.toggle()

        if isVibrationEnabled {
            // 振動有効化時の処理
            if let heartbeat = viewModel.currentHeartbeat {
                if vibrationService.isValidBPM(heartbeat.bpm) {
                    vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
                }
            } else {
                // データがない場合は手動で更新を試みる
                viewModel.refreshHeartbeat()
            }
        } else {
            // 振動無効化時の処理
            vibrationService.stopVibration()
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

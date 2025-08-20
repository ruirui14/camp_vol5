// Views/HeartbeatDetailView.swift
// 修正版 - 画像位置を正確に再現 + 背景画像管理機能

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

    private let persistenceManager = PersistenceManager.shared

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: HeartbeatDetailViewModel(userId: userId))
    }

    init(userWithHeartbeat: UserWithHeartbeat) {
        _viewModel = StateObject(
            wrappedValue: HeartbeatDetailViewModel(userWithHeartbeat: userWithHeartbeat)
        )
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        // 透明なナビゲーションバーの設定
        .navigationBarBackgroundTransparent()
        .toolbar {
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
                    // 振動制御ボタン
                    Button(action: {
                        toggleVibration()
                    }) {
                        Image(systemName: isVibrationEnabled ? "heart.circle.fill" : "heart.circle")
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
        .onAppear {
            viewModel.startContinuousMonitoring()
            loadPersistedData()

            // 保存された背景色を読み込み
            savedBackgroundColor = persistenceManager.loadBackgroundColor()

            // 初期状態で振動を有効にし、既にデータがある場合は振動開始
            if isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
                if vibrationService.isValidBPM(heartbeat.bpm) {
                    vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
                }
            }
        }
        .onDisappear {
            viewModel.stopMonitoring()
            vibrationService.stopVibration()
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
                // ImageEditViewが閉じられたときにハートの位置とサイズを再読み込み
                let heartPosition = persistenceManager.loadHeartPosition()
                heartOffset = heartPosition

                // ハートサイズの更新
                heartSize = persistenceManager.loadHeartSize()

                // 背景色の更新
                savedBackgroundColor = persistenceManager.loadBackgroundColor()

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
                    editedImage = selectedImage

                    // 画像と変形情報を永続化
                    if let image = selectedImage {
                        persistenceManager.saveBackgroundImage(image)
                    }
                    persistenceManager.saveImageTransform(offset: imageOffset, scale: imageScale)

                    showingImageEditor = false
                }
            )
        }
        .fullScreenCover(
            isPresented: $showingCardBackgroundEditSheet,
            onDismiss: {
                // CardBackgroundEditViewが閉じられたときもハートサイズを更新
                heartSize = persistenceManager.loadHeartSize()

                // 背景色の更新
                savedBackgroundColor = persistenceManager.loadBackgroundColor()

                // 振動を再開（振動が有効で心拍データがある場合）
                if isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
                    if vibrationService.isValidBPM(heartbeat.bpm) {
                        vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
                    }
                }
            }
        ) {
            if let user = viewModel.user {
                CardBackgroundEditView(userId: user.id)
            }
        }
    }

    private func loadPersistedData() {
        // 保存された画像を読み込み
        if let savedImage = persistenceManager.loadBackgroundImage() {
            selectedImage = savedImage
            editedImage = savedImage
        }

        // 保存された変形情報を読み込み
        let transform = persistenceManager.loadImageTransform()
        imageOffset = transform.offset
        imageScale = transform.scale
        // ハートの位置を読み込み
        let heartPosition = persistenceManager.loadHeartPosition()
        heartOffset = heartPosition
        // ハートのサイズを読み込み
        heartSize = persistenceManager.loadHeartSize()
    }

    private var heartbeatDisplayView: some View {
        HeartAnimationView(
            bpm: viewModel.currentHeartbeat?.bpm ?? 0,
            heartSize: heartSize,
            showBPM: true,
            enableHaptic: false,  // VibrationServiceと競合しないよう無効
            heartColor: .red
        )
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
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

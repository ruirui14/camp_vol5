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
    @State private var selectedImage: UIImage?
    @State private var editedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingImageEditor = false
    @State private var imageOffset = CGSize.zero
    @State private var imageScale: CGFloat = 1.0

    private let persistenceManager = PersistenceManager.shared

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: HeartbeatDetailViewModel(userId: userId))
    }

    init(userWithHeartbeat: UserWithHeartbeat) {
        _viewModel = StateObject(
            wrappedValue: HeartbeatDetailViewModel(userWithHeartbeat: userWithHeartbeat))
    }

    var body: some View {
        ZStack {
            // 白い背景
            Color.white
                .ignoresSafeArea()

            // 背景画像（編集された状態を反映）
            if let image = editedImage ?? selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .ignoresSafeArea()
            } else {
                // デフォルトのグラデーション背景
                LinearGradient(
                    gradient: Gradient(colors: [.main, .accent]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 20) {
                // 既存のコンテンツ
                Spacer()
                Spacer()
                Spacer()
                VStack(spacing: 8) {
                    heartbeatDisplayView

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
        }
        .navigationTitle(viewModel.user?.name ?? "読み込み中...")
        .navigationBarTitleDisplayMode(.inline)
        // 透明なナビゲーションバーの設定
        .navigationBarBackgroundTransparent()
        .navigationBarTitleTextColor(.white)
        .navigationBarItems(
            trailing:
                Menu {
                    Button("新しい画像を選択") {
                        showingImagePicker = true
                    }

                    if selectedImage != nil {
                        Button("現在の画像を再編集") {
                            showingImageEditor = true
                        }
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
        )
        .onAppear {
            viewModel.startContinuousMonitoring()
            loadPersistedData()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
        .sheet(isPresented: $showingImagePicker) {
            SimplePhotoPickerView(
                selectedImage: $selectedImage,
                onImageSelected: {
                    if selectedImage != nil {
                        showingImageEditor = true
                    }
                })
        }
        .fullScreenCover(isPresented: $showingImageEditor) {
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
    }

    // MARK: - Helper Methods

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
    }

    private var heartbeatDisplayView: some View {
        ZStack {
            Image("heart_beat")
                .resizable()
                .scaledToFill()
                .frame(width: 105, height: 92)
                .clipShape(Circle())

            Text(viewModel.currentHeartbeat?.bpm.description ?? "--")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

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
    @StateObject private var backgroundImageManager: BackgroundImageManager
    @State private var showingImagePicker = false
    @State private var showingImageEditor = false
    @State private var selectedImage: UIImage?
    @State private var heartOffset: CGSize = .zero
    @State private var tempHeartOffset: CGSize = .zero
    @State private var viewSize: CGSize = .zero

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: HeartbeatDetailViewModel(userId: userId))
        _backgroundImageManager = StateObject(wrappedValue: BackgroundImageManager(userId: userId))
    }

    init(userWithHeartbeat: UserWithHeartbeat) {
        _viewModel = StateObject(
            wrappedValue: HeartbeatDetailViewModel(userWithHeartbeat: userWithHeartbeat))
        _backgroundImageManager = StateObject(
            wrappedValue: BackgroundImageManager(userId: userWithHeartbeat.user.id))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image or gradient
                backgroundView(geometry: geometry)

                VStack(spacing: 20) {
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
                            .foregroundColor(
                                backgroundImageManager.getFinalDisplayImage() != nil
                                    ? .white : .gray
                            )
                            .shadow(
                                color: backgroundImageManager.getFinalDisplayImage() != nil
                                    ? Color.black.opacity(0.5) : Color.clear,
                                radius: 1, x: 0, y: 1)
                        } else {
                            Text("No data available")
                                .font(.caption)
                                .foregroundColor(
                                    backgroundImageManager.getFinalDisplayImage() != nil
                                        ? .white : .gray
                                )
                                .shadow(
                                    color: backgroundImageManager.getFinalDisplayImage() != nil
                                        ? Color.black.opacity(0.5) : Color.clear,
                                    radius: 1, x: 0, y: 1)
                        }
                    }
                    .offset(heartOffset)

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
            .onAppear {
                viewSize = geometry.size
            }
        }
        .navigationTitle(viewModel.user?.name ?? "読み込み中...")
        .navigationBarTitleDisplayMode(.inline)
        .gradientNavigationBar(colors: [.main, .accent], titleColor: .white)
        .navigationBarItems(
            trailing:
                Menu {
                    Button("新しい画像を選択") {
                        showingImagePicker = true
                    }

                    if backgroundImageManager.getOriginalImageForReEdit() != nil {
                        Button("現在の画像を再編集") {
                            if let originalImage =
                                backgroundImageManager.getOriginalImageForReEdit()
                            {
                                selectedImage = originalImage
                                showingImageEditor = true
                            }
                        }
                    }

                    if backgroundImageManager.getFinalDisplayImage() != nil {
                        Button("背景画像をリセット", role: .destructive) {
                            backgroundImageManager.resetBackgroundImage()
                        }
                    }
                } label: {
                    Image(systemName: "photo")
                        .foregroundColor(.white)
                }
        )
        .onAppear {
            viewModel.startContinuousMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
        .sheet(isPresented: $showingImagePicker) {
            PHPickerViewControllerWrapper(isPresented: $showingImagePicker) { image in
                backgroundImageManager.setOriginalImage(image)
                selectedImage = image
                showingImageEditor = true
            }
        }
        .fullScreenCover(isPresented: $showingImageEditor) {
            if let image = selectedImage {
                ImageEditView(
                    image: image,
                    initialTransform: backgroundImageManager.currentTransform,
                    onComplete: { transform in
                        backgroundImageManager.saveEditedResult(transform)
                        showingImageEditor = false
                        selectedImage = nil
                    },
                    onCancel: {
                        showingImageEditor = false
                        selectedImage = nil
                    }
                )
            }
        }
    }

    // MARK: - View Components

    private func backgroundView(geometry: GeometryProxy) -> some View {
        Group {
            if backgroundImageManager.isLoading {
                ProgressView("背景画像を読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            } else if let editedImage = backgroundImageManager.getFinalDisplayImage() {
                SimpleBackgroundImageView(image: editedImage)
                    .overlay(
                        Color.black.opacity(0.3)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    )
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [.main, .accent]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // 保存中のオーバーレイ
            if backgroundImageManager.isSaving {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("編集結果を保存中...")
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                }
            }
        }
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
                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

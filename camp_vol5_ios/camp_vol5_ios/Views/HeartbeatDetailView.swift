// Views/HeartbeatDetailView.swift
// 修正版 - 画像位置を正確に再現

import PhotosUI
import SwiftUI
import UIKit

struct ImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct HeartbeatDetailView: View {
    @StateObject private var viewModel: HeartbeatDetailViewModel
    @State private var backgroundImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingImageEditor = false
    @State private var previewImage: UIImage?
    @State private var editorImage: UIImage?
    @State private var imageOffset: CGSize = .zero
    @State private var imageScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var tempImageOffset: CGSize = .zero
    @State private var tempImageScale: CGFloat = 1.0
    @State private var tempLastScale: CGFloat = 1.0
    @State private var heartOffset: CGSize = .zero
    @State private var tempHeartOffset: CGSize = .zero
    @State private var viewSize: CGSize = .zero

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: HeartbeatDetailViewModel(userId: userId))
    }

    init(userWithHeartbeat: UserWithHeartbeat) {
        _viewModel = StateObject(
            wrappedValue: HeartbeatDetailViewModel(userWithHeartbeat: userWithHeartbeat))
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
                            .foregroundColor(backgroundImage != nil ? .white : .gray)
                            .shadow(
                                color: backgroundImage != nil
                                    ? Color.black.opacity(0.5) : Color.clear,
                                radius: 1, x: 0, y: 1)
                        } else {
                            Text("No data available")
                                .font(.caption)
                                .foregroundColor(backgroundImage != nil ? .white : .gray)
                                .shadow(
                                    color: backgroundImage != nil
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
                Button(action: {
                    showingImagePicker = true
                }) {
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
            PHPickerViewControllerWrapper(isPresented: $showingImagePicker) { selectedImage in
                tempImageOffset = .zero
                tempImageScale = 1.0
                tempLastScale = 1.0
                tempHeartOffset = .zero

                DispatchQueue.main.async {
                    self.previewImage = selectedImage
                    self.editorImage = selectedImage
                }
            }
        }
        .fullScreenCover(
            item: Binding<ImageWrapper?>(
                get: {
                    if let editorImage = editorImage {
                        return ImageWrapper(image: editorImage)
                    }
                    return nil
                },
                set: { _ in editorImage = nil }
            )
        ) { imageWrapper in
            ImageEditorView(
                image: imageWrapper.image,
                offset: $tempImageOffset,
                scale: $tempImageScale,
                lastScale: $tempLastScale,
                heartOffset: $tempHeartOffset,
                onApply: {
                    backgroundImage = imageWrapper.image
                    imageOffset = tempImageOffset
                    imageScale = tempImageScale
                    lastScale = tempLastScale
                    heartOffset = tempHeartOffset
                    editorImage = nil
                },
                onCancel: {
                    editorImage = nil
                }
            )
        }
    }

    // MARK: - View Components

    private func backgroundView(geometry: GeometryProxy) -> some View {
        Group {
            if let backgroundImage = backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: geometry.size.width * imageScale,
                        height: geometry.size.height * imageScale
                    )
                    .position(
                        x: geometry.size.width / 2 + imageOffset.width,
                        y: geometry.size.height / 2 + imageOffset.height
                    )
                    .clipped()
                    .frame(width: geometry.size.width, height: geometry.size.height)
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

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

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: HeartbeatDetailViewModel(userId: userId))
    }

    init(userWithHeartbeat: UserWithHeartbeat) {
        _viewModel = StateObject(
            wrappedValue: HeartbeatDetailViewModel(userWithHeartbeat: userWithHeartbeat))
    }

    var body: some View {
        ZStack {
            // Background image or gradient
            backgroundView

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
                            color: backgroundImage != nil ? Color.black.opacity(0.5) : Color.clear,
                            radius: 1, x: 0, y: 1)
                    } else {
                        Text("No data available")
                            .font(.caption)
                            .foregroundColor(backgroundImage != nil ? .white : .gray)
                            .shadow(
                                color: backgroundImage != nil ? Color.black.opacity(0.5) : Color.clear,
                                radius: 1, x: 0, y: 1)
                    }
                }
                .offset(heartOffset)  // ハート全体のオフセットを適用

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .padding()
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
        .onChange(of: viewModel.isMonitoring) { isMonitoring in
            if isMonitoring {
                viewModel.startContinuousMonitoring()
            } else {
                viewModel.stopMonitoring()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            PHPickerViewControllerWrapper(isPresented: $showingImagePicker) { selectedImage in
                print("Setting previewImage: \(selectedImage.size)")

                // プレビュー用の変形をリセット
                tempImageOffset = .zero
                tempImageScale = 1.0
                tempLastScale = 1.0
                tempHeartOffset = .zero

                print("Preview image set, size: \(selectedImage.size)")

                // 画像を設定してエディタを表示 (メインスレッドで実行)
                DispatchQueue.main.async {
                    self.previewImage = selectedImage
                    self.editorImage = selectedImage
                    print("Setting editorImage on main thread, exists: \(self.editorImage != nil)")
                    // fullScreenCover will automatically trigger when editorImage becomes non-nil
                }
            }
        }
        .fullScreenCover(
            item: Binding<ImageWrapper?>(
                get: {
                    if let editorImage = editorImage {
                        print(
                            "FullScreenCover: Creating ImageWrapper with image size: \(editorImage.size)"
                        )
                        return ImageWrapper(image: editorImage)
                    } else {
                        print("FullScreenCover: editorImage is nil, returning nil")
                        return nil
                    }
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
                    // 適用ボタンが押されたら背景に設定
                    print("FullScreenCover: Applying image with size: \(imageWrapper.image.size)")
                    backgroundImage = imageWrapper.image
                    imageOffset = tempImageOffset
                    imageScale = tempImageScale
                    lastScale = tempLastScale
                    heartOffset = tempHeartOffset  // ハートのオフセットも保存
                    editorImage = nil
                },
                onCancel: {
                    // キャンセルボタンが押されたらクリア
                    editorImage = nil
                }
            )
        }

    }

    // MARK: - View Components

    private var backgroundView: some View {
        Group {
            if let backgroundImage = backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .ignoresSafeArea()
                    .overlay(
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                    )
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [.main, .accent]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
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

struct HeartbeatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HeartbeatDetailView(userId: "preview_user_id")
            .environmentObject(AuthenticationManager())
    }
}

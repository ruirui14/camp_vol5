import PhotosUI
import SwiftUI

struct HeartbeatDetailView: View {
    @StateObject private var viewModel: HeartbeatDetailViewModel
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var backgroundImage: UIImage?
    @State private var showingImagePicker = false

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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                PhotosPicker(selection: $selectedImageItem, matching: .images) {
                    Image(systemName: "photo")
                        .foregroundColor(.white)
                }
            }
        }
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
        .onChange(of: selectedImageItem) { _ in
            Task {
                if let data = try? await selectedImageItem?.loadTransferable(type: Data.self) {
                    backgroundImage = UIImage(data: data)
                }
            }
        }
    }

    // MARK: - View Components

    private var backgroundView: some View {
        Group {
            if let backgroundImage = backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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

import SwiftUI

struct ListHeartBeatsView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: ListHeartBeatsViewModel
    @State private var showingQRShareSheet = false
    @State private var showingQRScannerSheet = false
    @State private var showingSettingsSheet = false
    @State private var backgroundImageManagers: [String: BackgroundImageManager] = [:]

    init() {
        // 初期化時はダミーの AuthenticationManager を使用
        // 実際の AuthenticationManager は @EnvironmentObject で注入される
        _viewModel = StateObject(
            wrappedValue: ListHeartBeatsViewModel(
                authenticationManager: AuthenticationManager()
            ))
        // BackgroundImageManagersは認証後に初期化
        _backgroundImageManagers = State(initialValue: [:])
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                MainAccentGradient()

                VStack {
                    if viewModel.isLoading {
                        ProgressView("読み込み中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)

                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()

                            Button("再試行") {
                                viewModel.clearError()
                                if authenticationManager.isGoogleAuthenticated {
                                    viewModel.loadFollowingUsersWithHeartbeats()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.followingUsersWithHeartbeats.isEmpty {
                        // フォローユーザーがいない場合の表示
                        emptyFollowingContent
                    } else {
                        // フォローユーザーのリスト表示
                        followingUsersList
                    }
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                viewModel.updateAuthenticationManager(authenticationManager)
                // フォローしているユーザーの背景画像を読み込み
                loadBackgroundImages()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification)
            ) { _ in
                // アプリがフォアグラウンドに戻った時に背景画像を更新
                loadBackgroundImages()
            }
            .onChange(of: viewModel.followingUsersWithHeartbeats.count) { _ in
                // フォローユーザーが変更された時に背景画像を更新
                loadBackgroundImages()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .foregroundColor(.main)
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingQRScannerSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                    }
                    .foregroundColor(.main)

                    Button(action: {
                        showingQRShareSheet = true
                    }) {
                        Image(systemName: "qrcode")
                    }
                    .foregroundColor(.main)
                }
            }
            .sheet(isPresented: $showingQRShareSheet) {
                QRCodeShareView()
                    .environmentObject(authenticationManager)
            }
            .sheet(isPresented: $showingQRScannerSheet) {
                QRCodeScannerView()
                    .environmentObject(authenticationManager)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
                    .environmentObject(authenticationManager)
            }
        }
    }

    // MARK: - View Components

    private var emptyFollowingContent: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .padding(.bottom, 10)

                    Text("フォロー中のユーザーがいません")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)

                    Text("QRコードスキャンでユーザーを追加してみましょう")
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)

                    Button("ユーザーを追加") {
                        showingQRScannerSheet = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
                .contentShape(Rectangle())
            }
            .refreshable {
                print("refresh")
                viewModel.loadFollowingUsersWithHeartbeats()
            }
        }
    }

    private var followingUsersList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(viewModel.followingUsersWithHeartbeats) { userWithHeartbeat in
                    NavigationLink(
                        destination: HeartbeatDetailView(userWithHeartbeat: userWithHeartbeat)
                    ) {
                        UserHeartbeatCard(
                            userWithHeartbeat: userWithHeartbeat,
                            customBackgroundImage: backgroundImageManagers[
                                userWithHeartbeat.user.id]?.currentEditedImage
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top, 20)
        }
        .refreshable {
            viewModel.loadFollowingUsersWithHeartbeats()
            loadBackgroundImages()
        }
    }

    // MARK: - Helper Methods

    private func loadBackgroundImages() {
        for userWithHeartbeat in viewModel.followingUsersWithHeartbeats {
            let userId = userWithHeartbeat.user.id
            if let existingManager = backgroundImageManagers[userId] {
                // 既存のManagerがある場合は、ストレージから最新データを再読み込み
                existingManager.refreshFromStorage()
            } else {
                // 新しいManagerを作成
                backgroundImageManagers[userId] = BackgroundImageManager(userId: userId)
            }
        }
    }

}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

struct ListHeartBeatsView_Previews: PreviewProvider {
    static var previews: some View {
        ListHeartBeatsView()
            .environmentObject(AuthenticationManager())
    }
}

import SwiftUI

// MARK: - Navigation Destinations

enum NavigationDestination: Hashable {
    case settings
    case qrScanner
    case heartbeatDetail(UserWithHeartbeat)
}

struct ListHeartBeatsView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: ListHeartBeatsViewModel
    @State private var backgroundImageManagers: [String: BackgroundImageManager] = [:]
    @State private var backgroundImageRefreshTrigger = 0
    @State private var navigationPath = NavigationPath()

    init() {
        // 初期化時はダミーの AuthenticationManager を使用
        // 実際の AuthenticationManager は @EnvironmentObject で注入される
        _viewModel = StateObject(
            wrappedValue: ListHeartBeatsViewModel(
                authenticationManager: AuthenticationManager()
            )
        )
        // BackgroundImageManagersは認証後に初期化
        _backgroundImageManagers = State(initialValue: [:])
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                    for: UIApplication.willEnterForegroundNotification
                )
            ) { _ in
                // アプリがフォアグラウンドに戻った時に背景画像を更新
                loadBackgroundImages()
            }
            .onReceive(viewModel.$followingUsersWithHeartbeats) { usersWithHeartbeats in
                // フォローユーザーのデータが更新された時に背景画像を更新
                if !usersWithHeartbeats.isEmpty {
                    loadBackgroundImages()
                    // BackgroundImageManagerの初期化完了を待ってから再度UI更新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        checkAndTriggerUIUpdate()
                    }
                }
            }
            .onChange(of: viewModel.isLoading) { isLoading in
                // データ読み込み完了時に背景画像を更新
                if !isLoading && !viewModel.followingUsersWithHeartbeats.isEmpty {
                    loadBackgroundImages()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        navigationPath.append(NavigationDestination.settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.main)
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        navigationPath.append(NavigationDestination.qrScanner)
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.main)
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .settings:
                    SettingsView().environmentObject(authenticationManager)
                case .qrScanner:
                    QRCodeScannerView().environmentObject(authenticationManager)
                case let .heartbeatDetail(userWithHeartbeat):
                    HeartbeatDetailView(userWithHeartbeat: userWithHeartbeat)
                }
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
                        navigationPath.append(NavigationDestination.qrScanner)
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
                viewModel.loadFollowingUsersWithHeartbeats()
            }
        }
    }

    private var followingUsersList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(viewModel.followingUsersWithHeartbeats) { userWithHeartbeat in
                    Button {
                        navigationPath.append(
                            NavigationDestination.heartbeatDetail(userWithHeartbeat))
                    } label: {
                        UserHeartbeatCard(
                            userWithHeartbeat: userWithHeartbeat,
                            customBackgroundImage: backgroundImageManagers[
                                userWithHeartbeat.user.id
                            ]?.currentEditedImage
                        )
                        .id(
                            "\(userWithHeartbeat.user.id)-\(backgroundImageManagers[userWithHeartbeat.user.id]?.currentEditedImage != nil ? "with-image" : "no-image")-\(backgroundImageRefreshTrigger)"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .id("following-users-\(backgroundImageRefreshTrigger)")
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

        // UI更新をトリガー
        DispatchQueue.main.async {
            self.backgroundImageRefreshTrigger += 1
        }
    }

    private func checkAndTriggerUIUpdate() {
        // BackgroundImageManagerの読み込み状況をチェック
        var allLoadingComplete = true
        var hasImages = false

        for (_, manager) in backgroundImageManagers {
            if manager.isLoading {
                allLoadingComplete = false
            }
            if manager.currentEditedImage != nil {
                hasImages = true
            }
        }

        if allLoadingComplete || hasImages {
            backgroundImageRefreshTrigger += 1
        } else if !allLoadingComplete {
            // まだ読み込み中の場合は少し待ってから再チェック
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                checkAndTriggerUIUpdate()
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

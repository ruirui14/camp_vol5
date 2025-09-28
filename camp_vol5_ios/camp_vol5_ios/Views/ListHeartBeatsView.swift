import Combine
import SwiftUI

// MARK: - Navigation Destinations

enum NavigationDestination: Hashable {
    case settings
    case qrScanner
    case heartbeatDetail(String)  // userIdを直接渡す

    func hash(into hasher: inout Hasher) {
        switch self {
        case .settings:
            hasher.combine("settings")
        case .qrScanner:
            hasher.combine("qrScanner")
        case .heartbeatDetail(let userId):
            hasher.combine("heartbeatDetail")
            hasher.combine(userId)
        }
    }
}

struct ListHeartBeatsView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: ListHeartBeatsViewModel
    @State private var backgroundImageManagers: [String: BackgroundImageManager] = [:]
    @State private var uiUpdateTrigger = false  // UI更新をトリガーするためのフラグ
    @State private var navigationPath = NavigationPath()
    @State private var isStatusBarHidden = false
    @State private var persistentSystemOverlaysVisibility: Visibility = .automatic
    @State private var isLoadingBackgroundImages = false  // 重複読み込み防止フラグ
    @State private var lastLoadTime: Date = .distantPast  // 最後の読み込み時刻
    @State private var hasLoadedOnce = false  // 初回読み込み完了フラグ

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
                                if authenticationManager.isAuthenticated {
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

                // データ読み込みを確実に実行（キャッシュがあってもUIが初期表示時は実行）
                viewModel.loadFollowingUsersWithHeartbeats()

                // データが既に存在する場合は背景画像を読み込み
                if !viewModel.followingUsersWithHeartbeats.isEmpty {
                    loadBackgroundImages()
                }
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
                    let needsLoading = usersWithHeartbeats.contains { userWithHeartbeat in
                        let userId = userWithHeartbeat.user.id
                        // Managerが存在しないか、Managerがあっても画像が読み込まれていない場合
                        return backgroundImageManagers[userId] == nil ||
                               backgroundImageManagers[userId]?.currentEditedImage == nil
                    }

                    if needsLoading {
                        loadBackgroundImages()
                    }
                }
            }
            .onChange(of: viewModel.isLoading) { isLoading in
                // データ読み込み完了時に背景画像を更新
                if !isLoading && !viewModel.followingUsersWithHeartbeats.isEmpty {
                    loadBackgroundImages()
                }
            }
            .onChange(of: uiUpdateTrigger) { _ in
                // UI更新トリガー - Stateが変更されることでビューが再描画される（単純な再描画のみ）
                print("🔄 [ListHeartBeatsView] UI更新トリガーが変更されました")
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
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                viewModel.changeSortOption(option)
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if viewModel.currentSortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.main)
                    }

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
                case let .heartbeatDetail(userId):
                    HeartbeatDetailView(
                        userId: userId,
                        isStatusBarHidden: $isStatusBarHidden,
                        isPersistentSystemOverlaysHidden: $persistentSystemOverlaysVisibility
                    )
                }
            }
        }
        .statusBarHidden(isStatusBarHidden)
        .persistentSystemOverlays(persistentSystemOverlaysVisibility)
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
            VStack(spacing: CardConstants.cardVerticalSpacing) {
                ForEach(viewModel.followingUsersWithHeartbeats, id: \.user.id) {
                    userWithHeartbeat in
                    UserHeartbeatCardWrapper(
                        userWithHeartbeat: userWithHeartbeat,
                        backgroundImageManager: backgroundImageManagers[userWithHeartbeat.user.id]
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print(
                            "Tapping card for user: \(userWithHeartbeat.user.name), id: \(userWithHeartbeat.user.id)"
                        )
                        print(
                            "Background image for \(userWithHeartbeat.user.id): \(backgroundImageManagers[userWithHeartbeat.user.id]?.currentEditedImage != nil ? "present" : "nil")"
                        )
                        navigationPath.append(
                            NavigationDestination.heartbeatDetail(userWithHeartbeat.user.id))
                    }
                    .id("card-\(userWithHeartbeat.user.id)")
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
        let now = Date()

        // 重複呼び出し防止: 既に読み込み中の場合はスキップ
        if isLoadingBackgroundImages {
            print("=== SKIPPING BACKGROUND IMAGES LOAD (already loading) ===")
            return
        }

        // 初回読み込み以降は、最後の読み込みから1秒以内の場合はスキップ
        if hasLoadedOnce && now.timeIntervalSince(lastLoadTime) < 1.0 {
            print("=== SKIPPING BACKGROUND IMAGES LOAD (too recent) ===")
            return
        }

        isLoadingBackgroundImages = true
        lastLoadTime = now
        print("=== LOADING BACKGROUND IMAGES ===")

        Task {
            for userWithHeartbeat in viewModel.followingUsersWithHeartbeats {
                let userId = userWithHeartbeat.user.id
                print(
                    "Loading background image for user: \(userWithHeartbeat.user.name) (ID: \(userId))"
                )

                await MainActor.run {
                    if backgroundImageManagers[userId] == nil {
                        // 新しいManagerを作成（初期化時に自動的にloadPersistedImages()が呼ばれる）
                        print("  Creating new manager for \(userId)")
                        backgroundImageManagers[userId] = BackgroundImageManager(userId: userId)
                    } else {
                        // 既存のManagerがある場合は、初回読み込み以降のみrefreshを実行
                        if hasLoadedOnce, let existingManager = backgroundImageManagers[userId] {
                            if existingManager.currentEditedImage == nil && !existingManager.isLoading {
                                print("  Refreshing existing manager for \(userId) (no image loaded)")
                                existingManager.refreshFromStorage()
                            } else {
                                print("  Existing manager for \(userId) already has image or is loading")
                            }
                        } else {
                            print("  Skipping refresh for \(userId) during initial load")
                        }
                    }
                }

                // BackgroundImageManagerの初期化を少し待つ
                try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3秒待機

                await MainActor.run {
                    let hasImage = self.backgroundImageManagers[userId]?.currentEditedImage != nil
                    print("  Image loaded for \(userWithHeartbeat.user.name): \(hasImage)")
                }
            }

            await MainActor.run {
                print("=== BACKGROUND IMAGES LOADED ===")
                // 実際に新しい画像が読み込まれた場合のみUI更新をトリガー
                let hasNewImages = self.backgroundImageManagers.values.contains { manager in
                    manager.currentEditedImage != nil
                }
                if hasNewImages {
                    self.uiUpdateTrigger.toggle()
                }

                // 読み込み完了フラグをリセット
                self.isLoadingBackgroundImages = false
                self.hasLoadedOnce = true
            }
        }
    }

    private func checkAndTriggerUIUpdate() {
        // BackgroundImageManagerの読み込み状況をチェック
        var allLoadingComplete = true

        for (_, manager) in backgroundImageManagers {
            if manager.isLoading {
                allLoadingComplete = false
            }
        }

        if !allLoadingComplete {
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

struct UserHeartbeatCardWrapper: View {
    let userWithHeartbeat: UserWithHeartbeat
    let backgroundImageManager: BackgroundImageManager?
    @State private var backgroundImage: UIImage?

    init(userWithHeartbeat: UserWithHeartbeat, backgroundImageManager: BackgroundImageManager?) {
        self.userWithHeartbeat = userWithHeartbeat
        self.backgroundImageManager = backgroundImageManager

        let initialImage = backgroundImageManager?.currentEditedImage
        print("📱 [UserHeartbeatCardWrapper] init for user: \(userWithHeartbeat.user.name)")
        print(
            "📱 [UserHeartbeatCardWrapper] init - backgroundImageManager: \(backgroundImageManager != nil ? "存在" : "nil")"
        )
        print(
            "📱 [UserHeartbeatCardWrapper] init - initialImage: \(initialImage != nil ? "存在" : "nil")"
        )

        // 初期化時点で画像が既に利用可能な場合は設定
        self._backgroundImage = State(initialValue: initialImage)
    }

    var body: some View {
        UserHeartbeatCard(
            userWithHeartbeat: userWithHeartbeat,
            customBackgroundImage: backgroundImage,
            displayName: nil,
            displayBPM: nil
        )
        .onAppear {
            print("📱 [UserHeartbeatCardWrapper] onAppear for user: \(userWithHeartbeat.user.name)")
            // onAppearでは画像が既にnilでない場合は更新しない（無限ループ防止）
            if backgroundImage == nil {
                updateBackgroundImage()
            }
        }
        .onChange(of: backgroundImageManager?.currentEditedImage) { newImage in
            // 現在の画像と新しい画像が異なる場合のみ更新
            if backgroundImage != newImage {
                print(
                    "📱 [UserHeartbeatCardWrapper] currentEditedImage onChange for user: \(userWithHeartbeat.user.name), hasImage: \(newImage != nil)"
                )
                updateBackgroundImage()
            }
        }
        .task {
            // 非同期でバックグラウンド画像の読み込み完了を待つ
            await checkBackgroundImagePeriodically()
        }
    }

    private func updateBackgroundImage() {
        let newImage = backgroundImageManager?.currentEditedImage

        // 同じ画像の場合は更新をスキップ
        guard backgroundImage != newImage else { return }

        print(
            "📱 [UserHeartbeatCardWrapper] updateBackgroundImage for user: \(userWithHeartbeat.user.name), hasImage: \(newImage != nil)"
        )
        backgroundImage = newImage
    }

    @MainActor
    private func checkBackgroundImagePeriodically() async {
        // 最初の画像が利用可能かチェック
        if backgroundImage == nil {
            for _ in 0..<10 {  // 最大5秒間（0.5秒間隔で10回）
                try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5秒待機

                if let newImage = backgroundImageManager?.currentEditedImage,
                    backgroundImage != newImage
                {  // 重複更新チェック
                    print(
                        "📱 [UserHeartbeatCardWrapper] 遅延読み込み成功 for user: \(userWithHeartbeat.user.name)"
                    )
                    backgroundImage = newImage
                    break
                }
            }
        }
    }
}

struct ListHeartBeatsView_Previews: PreviewProvider {
    static var previews: some View {
        ListHeartBeatsView()
            .environmentObject(AuthenticationManager())
    }
}

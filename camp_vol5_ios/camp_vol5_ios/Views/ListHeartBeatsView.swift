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
    @StateObject private var viewModel = ListHeartBeatsViewModel()
    @StateObject private var backgroundImageCoordinator = BackgroundImageCoordinator()
    @State private var navigationPath = NavigationPath()
    @State private var isStatusBarHidden = false
    @State private var persistentSystemOverlaysVisibility: Visibility = .automatic
    @State private var hasAppearedOnce = false
    @State private var isEditMode = false

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
                        ErrorStateView(
                            errorMessage: errorMessage,
                            onRetry: {
                                viewModel.refreshData()
                            }
                        )
                    } else if viewModel.followingUsersWithHeartbeats.isEmpty {
                        EmptyFollowingUsersView(
                            onAddUser: {
                                navigationPath.append(NavigationDestination.qrScanner)
                            },
                            onRefresh: {
                                viewModel.refreshData()
                            }
                        )
                    } else {
                        FollowingUsersListView(
                            users: viewModel.followingUsersWithHeartbeats,
                            backgroundImageCoordinator: backgroundImageCoordinator,
                            isEditMode: isEditMode,
                            onUserTapped: { userWithHeartbeat in
                                navigationPath.append(
                                    NavigationDestination.heartbeatDetail(userWithHeartbeat.user.id)
                                )
                            },
                            onRefresh: {
                                viewModel.refreshData()
                                backgroundImageCoordinator.loadBackgroundImages(
                                    for: viewModel.followingUsersWithHeartbeats)
                            },
                            onUnfollow: { userId in
                                viewModel.unfollowUser(userId: userId)
                            }
                        )
                    }
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                print("🔄 [ListHeartBeatsView] onAppear called")

                // 初回のみ実行
                if !hasAppearedOnce {
                    hasAppearedOnce = true
                    viewModel.loadFollowingUsersWithHeartbeats()

                    // データが既に存在する場合は背景画像を読み込み
                    if !viewModel.followingUsersWithHeartbeats.isEmpty {
                        backgroundImageCoordinator.loadBackgroundImages(
                            for: viewModel.followingUsersWithHeartbeats)
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification
                )
            ) { _ in
                // アプリがフォアグラウンドに戻った時に背景画像を更新
                backgroundImageCoordinator.loadBackgroundImages(
                    for: viewModel.followingUsersWithHeartbeats)
            }
            .onReceive(viewModel.$followingUsersWithHeartbeats) { usersWithHeartbeats in
                // フォローユーザーのデータが更新された時に背景画像を更新
                if !usersWithHeartbeats.isEmpty
                    && backgroundImageCoordinator.needsLoading(for: usersWithHeartbeats)
                {
                    backgroundImageCoordinator.loadBackgroundImages(for: usersWithHeartbeats)
                }
            }
            .onChange(of: viewModel.isLoading) { _, isLoading in
                // データ読み込み完了時に背景画像を更新
                if !isLoading && !viewModel.followingUsersWithHeartbeats.isEmpty {
                    backgroundImageCoordinator.loadBackgroundImages(
                        for: viewModel.followingUsersWithHeartbeats)
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
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isEditMode.toggle()
                        }
                    } label: {
                        Image(systemName: isEditMode ? "checkmark" : "pencil")
                            .foregroundColor(.main)
                    }

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
                    FollowUserView().environmentObject(authenticationManager)
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

}

struct ListHeartBeatsView_Previews: PreviewProvider {
    static var previews: some View {
        ListHeartBeatsView()
            .environmentObject(AuthenticationManager())
    }
}

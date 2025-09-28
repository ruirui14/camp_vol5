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
    @StateObject private var backgroundImageCoordinator = BackgroundImageCoordinator()
    @State private var navigationPath = NavigationPath()
    @State private var isStatusBarHidden = false
    @State private var persistentSystemOverlaysVisibility: Visibility = .automatic

    init() {
        // 初期化時はダミーの AuthenticationManager を使用
        // 実際の AuthenticationManager は @EnvironmentObject で注入される
        _viewModel = StateObject(
            wrappedValue: ListHeartBeatsViewModel(
                authenticationManager: AuthenticationManager()
            )
        )
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
                            backgroundImageManagers: backgroundImageCoordinator.backgroundImageManagers,
                            onUserTapped: { userWithHeartbeat in
                                navigationPath.append(
                                    NavigationDestination.heartbeatDetail(userWithHeartbeat.user.id)
                                )
                            },
                            onRefresh: {
                                viewModel.refreshData()
                                backgroundImageCoordinator.loadBackgroundImages(for: viewModel.followingUsersWithHeartbeats)
                            }
                        )
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
                    backgroundImageCoordinator.loadBackgroundImages(for: viewModel.followingUsersWithHeartbeats)
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification
                )
            ) { _ in
                // アプリがフォアグラウンドに戻った時に背景画像を更新
                backgroundImageCoordinator.loadBackgroundImages(for: viewModel.followingUsersWithHeartbeats)
            }
            .onReceive(viewModel.$followingUsersWithHeartbeats) { usersWithHeartbeats in
                // フォローユーザーのデータが更新された時に背景画像を更新
                if !usersWithHeartbeats.isEmpty && backgroundImageCoordinator.needsLoading(for: usersWithHeartbeats) {
                    backgroundImageCoordinator.loadBackgroundImages(for: usersWithHeartbeats)
                }
            }
            .onChange(of: viewModel.isLoading) { isLoading in
                // データ読み込み完了時に背景画像を更新
                if !isLoading && !viewModel.followingUsersWithHeartbeats.isEmpty {
                    backgroundImageCoordinator.loadBackgroundImages(for: viewModel.followingUsersWithHeartbeats)
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


}

struct ListHeartBeatsView_Previews: PreviewProvider {
    static var previews: some View {
        ListHeartBeatsView()
            .environmentObject(AuthenticationManager())
    }
}

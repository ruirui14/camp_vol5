import Combine
import SwiftUI

// MARK: - Navigation Destinations

enum NavigationDestination: Hashable {
    case settings
    case qrScanner
    case heartbeatDetail(String)  // userIdを直接渡す
    case ranking

    func hash(into hasher: inout Hasher) {
        switch self {
        case .settings:
            hasher.combine("settings")
        case .qrScanner:
            hasher.combine("qrScanner")
        case .heartbeatDetail(let userId):
            hasher.combine("heartbeatDetail")
            hasher.combine(userId)
        case .ranking:
            hasher.combine("ranking")
        }
    }
}

struct ListHeartBeatsView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @EnvironmentObject private var viewModelFactory: ViewModelFactory
    @StateObject private var viewModel = ListHeartBeatsViewModel()
    @ObservedObject private var themeManager = ColorThemeManager.shared
    @State private var navigationPath = NavigationPath()
    @State private var isStatusBarHidden = false
    @State private var persistentSystemOverlaysVisibility: Visibility = .automatic
    @State private var hasAppearedOnce = false
    @State private var isEditMode = false
    @State private var selectedThemeColor: Color = ColorThemeManager.shared.mainColor
    @State private var ignoreColorChange = false

    // UserDefaultsキー: 前回のフォロー数を保存
    private static let lastFollowingCountKey = "lastFollowingCount"

    // スケルトン表示数を計算（最小が保存数、最大6）
    private var skeletonCount: Int {
        let savedCount = UserDefaults.standard.integer(forKey: Self.lastFollowingCountKey)
        if savedCount == 0 {
            return 3  // 初回は3枚表示
        }
        return min(savedCount, 6)  // 最大6枚
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 背景グラデーション
                MainAccentGradient()

                VStack {
                    if viewModel.isLoading {
                        // ローディング中は前回のフォロー数に基づいた数のスケルトンを表示（最大6）
                        FollowingUsersListView(
                            users: (0..<skeletonCount).map { index in
                                UserWithHeartbeat(
                                    user: User(
                                        id: "skeleton_\(index)",
                                        name: "",
                                        inviteCode: "",
                                        allowQRRegistration: false
                                    ),
                                    heartbeat: nil,
                                    notificationEnabled: false,
                                    backgroundImageManager: nil
                                )
                            },
                            isEditMode: false,
                            onUserTapped: { _ in },
                            onRefresh: {},
                            onUnfollow: nil,
                            onToggleNotification: nil
                        )
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
                            isEditMode: isEditMode,
                            onUserTapped: { userWithHeartbeat in
                                navigationPath.append(
                                    NavigationDestination.heartbeatDetail(userWithHeartbeat.user.id)
                                )
                            },
                            onRefresh: {
                                viewModel.refreshData()
                            },
                            onUnfollow: { userId in
                                viewModel.unfollowUser(userId: userId)
                            },
                            onToggleNotification: { userId, enabled in
                                viewModel.toggleNotificationSetting(for: userId, enabled: enabled)
                            }
                        )
                    }
                }
            }
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                print("🔄 [ListHeartBeatsView] onAppear called")

                // 初回のみ実行
                if !hasAppearedOnce {
                    hasAppearedOnce = true
                    viewModel.loadFollowingUsersWithHeartbeats()
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: ColorThemeManager.didResetToDefaultsNotification
                )
            ) { _ in
                // カラーテーマがリセットされた時にColorPickerも同期
                ignoreColorChange = true
                selectedThemeColor = themeManager.mainColor
                DispatchQueue.main.async {
                    ignoreColorChange = false
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        navigationPath.append(NavigationDestination.settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(themeManager.iconColor)
                    }

                    Button {
                        navigationPath.append(NavigationDestination.ranking)
                    } label: {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(themeManager.iconColor)
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ColorPicker("", selection: $selectedThemeColor)
                        .labelsHidden()
                        .onChange(of: selectedThemeColor) { _, newColor in
                            // 初期化時やプログラムからの変更時は無視
                            guard !ignoreColorChange else { return }
                            withAnimation(.easeInOut(duration: 0.3)) {
                                themeManager.updateMainColor(newColor)
                            }
                        }

                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isEditMode.toggle()
                        }
                    } label: {
                        Image(systemName: isEditMode ? "checkmark" : "pencil")
                            .foregroundColor(themeManager.iconColor)
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
                            .foregroundColor(themeManager.iconColor)
                    }

                    Button {
                        navigationPath.append(NavigationDestination.qrScanner)
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(themeManager.iconColor)
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
                case .ranking:
                    ConnectionsRankingView(viewModelFactory: viewModelFactory)
                        .environmentObject(viewModelFactory)
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

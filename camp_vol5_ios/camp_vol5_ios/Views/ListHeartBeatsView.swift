import SwiftUI

struct ListHeartBeatsView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: ListHeartBeatsViewModel
    @State private var showingQRShareSheet = false
    @State private var showingQRScannerSheet = false
    @State private var showingSettingsSheet = false

    init() {
        // 初期化時はダミーの AuthenticationManager を使用
        // 実際の AuthenticationManager は @EnvironmentObject で注入される
        _viewModel = StateObject(
            wrappedValue: ListHeartBeatsViewModel(
                authenticationManager: AuthenticationManager()
            ))
    }

    var body: some View {
        NavigationView {
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
            .navigationTitle(
                authenticationManager.isGoogleAuthenticated
                    ? "鼓動一覧" : "Heart Beat Monitor"
            )
            .onAppear {
                viewModel.updateAuthenticationManager(authenticationManager)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettingsSheet = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingQRScannerSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                    }

                    Button(action: {
                        showingQRShareSheet = true
                    }) {
                        Image(systemName: "qrcode")
                    }
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
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("フォロー中のユーザーがいません")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("QRコードスキャンでユーザーを追加してみましょう")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("ユーザーを追加") {
                showingQRScannerSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var followingUsersList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(viewModel.followingUsersWithHeartbeats) { userWithHeartbeat in
                    NavigationLink(
                        destination: HeartbeatDetailView(userId: userWithHeartbeat.user.id)
                    ) {
                        UserHeartbeatCard(userWithHeartbeat: userWithHeartbeat)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top, 20)
        }
        .refreshable {
            viewModel.loadFollowingUsersWithHeartbeats()
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

import SwiftUI

struct ListHeartBeatsView: View {
    @StateObject private var viewModel = ListHeartBeatsViewModel()
    @StateObject private var authService = AuthService.shared
    @State private var showingQRShareSheet = false
    @State private var showingQRScannerSheet = false
    @State private var showingSettingsSheet = false

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
                            if authService.isGoogleAuthenticated {
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
                authService.isGoogleAuthenticated
                    ? "フォロー中" : "Heart Beat Monitor"
            )
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
            }
            .sheet(isPresented: $showingQRScannerSheet) {
                QRCodeScannerView()
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
            }
            .onAppear {
                if authService.isGoogleAuthenticated {
                    viewModel.loadFollowingUsersWithHeartbeats()
                }
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
        List {
            ForEach(viewModel.followingUsersWithHeartbeats) {
                userWithHeartbeat in
                NavigationLink(
                    destination: HeartbeatDetailView(
                        userId: userWithHeartbeat.user.id
                    )
                ) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userWithHeartbeat.user.name)
                                .font(.headline)

                            if let heartbeat = userWithHeartbeat.heartbeat {
                                Text(
                                    "更新: \(timeAgoString(from: heartbeat.timestamp))"
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            } else {
                                Text("データなし")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            if let heartbeat = userWithHeartbeat.heartbeat {
                                HStack {
                                    Text("\(heartbeat.bpm)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("bpm")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            } else {
                                Text("--")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .refreshable {
            viewModel.loadFollowingUsersWithHeartbeats()
        }
    }

    // MARK: - Helper Methods

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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
    }
}

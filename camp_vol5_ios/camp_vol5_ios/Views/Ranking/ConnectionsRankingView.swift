// Views/ConnectionsRankingView.swift
// 同接数ランキング表示画面
// 全期間の最大接続数でランキング表示

import SwiftUI

struct ConnectionsRankingView: View {
    @EnvironmentObject var viewModelFactory: ViewModelFactory
    @StateObject private var viewModel: ConnectionsRankingViewModel
    @ObservedObject private var themeManager = ColorThemeManager.shared
    @Environment(\.presentationMode) var presentationMode

    init(viewModelFactory: ViewModelFactory) {
        let vm = viewModelFactory.makeConnectionsRankingViewModel()
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if viewModel.isLoading {
                    RankingSkeletonList()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text("エラー")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("再試行") {
                            viewModel.refresh()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if viewModel.rankingUsers.isEmpty {
                    Text("ランキングデータがありません")
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(viewModel.rankingUsers.enumerated()), id: \.element.id) {
                                index, user in
                                RankingRow(rank: index + 1, user: user)
                                    .onAppear {
                                        viewModel.loadMoreIfNeeded(currentItem: user)
                                    }
                            }

                            // ローディングインジケーター
                            if viewModel.hasMoreData {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if !viewModel.rankingUsers.isEmpty {
                                // フッターメッセージ
                                VStack(spacing: 8) {
                                    Divider()
                                        .padding(.horizontal, 40)
                                    Text("TOP 100まで表示しています")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 20)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("戻る")
                        }
                    }
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text("同接ランキング")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("TOP 100")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
            .overlay(alignment: .top) {
                NavigationBarGradient(safeAreaHeight: geometry.safeAreaInsets.top)
            }
            .onAppear {
                viewModel.loadRanking()
            }
        }
    }
}

// MARK: - Ranking Row

struct RankingRow: View {
    let rank: Int
    let user: User

    var body: some View {
        HStack(spacing: 16) {
            // ランク表示
            Text("\(rank)")
                .font(.system(size: rankFontSize, weight: .bold, design: .rounded))
                .foregroundColor(rankColor)
                .frame(width: 40, alignment: .center)

            // ユーザー情報
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)

                if let maxConnections = user.maxConnections {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(maxConnections)人")
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }

                if let updatedAt = user.maxConnectionsUpdatedAt {
                    Text(formatDate(updatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // メダルアイコン
            if rank <= 3 {
                Image(systemName: medalIcon)
                    .font(.title)
                    .foregroundColor(medalColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var rankFontSize: CGFloat {
        switch rank {
        case 1: return 32
        case 2: return 28
        case 3: return 24
        default: return 20
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)  // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)  // Bronze
        default: return .primary
        }
    }

    private var medalIcon: String {
        switch rank {
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }

    private var medalColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .clear
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview("ランキング表示") {
    RankingPreviewContainer()
}

#Preview("スケルトン表示") {
    RankingSkeletonList()
        .background(Color(.systemGroupedBackground))
}

// MARK: - Preview Helper

struct RankingPreviewContainer: View {
    @StateObject private var viewModel = MockConnectionsRankingViewModel()

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(viewModel.rankingUsers.enumerated()), id: \.element.id) {
                            index, user in
                            RankingRow(rank: index + 1, user: user)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("戻る")
                            }
                        }
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }

                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text("同接ランキング")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("TOP 100")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white)
                        }
                    }
                }
                .overlay(alignment: .top) {
                    NavigationBarGradient(safeAreaHeight: geometry.safeAreaInsets.top)
                }
            }
        }
    }
}

// MARK: - Mock ViewModel

class MockConnectionsRankingViewModel: ObservableObject {
    @Published var rankingUsers: [User] = []

    init() {
        // モックデータを作成（10位まで）
        rankingUsers = [
            User(
                id: "user1",
                name: "田中太郎",
                inviteCode: "CODE1",
                allowQRRegistration: true,
                createdAt: Date(),
                updatedAt: Date(),
                maxConnections: 150,
                maxConnectionsUpdatedAt: Date().addingTimeInterval(-3600)
            ),
            User(
                id: "user2",
                name: "佐藤花子",
                inviteCode: "CODE2",
                allowQRRegistration: true,
                createdAt: Date(),
                updatedAt: Date(),
                maxConnections: 142,
                maxConnectionsUpdatedAt: Date().addingTimeInterval(-7200)
            ),
            User(
                id: "user3",
                name: "鈴木一郎",
                inviteCode: "CODE3",
                allowQRRegistration: true,
                createdAt: Date(),
                updatedAt: Date(),
                maxConnections: 138,
                maxConnectionsUpdatedAt: Date().addingTimeInterval(-10800)
            ),
            User(
                id: "user4",
                name: "高橋美咲",
                inviteCode: "CODE4",
                allowQRRegistration: true,
                createdAt: Date(),
                updatedAt: Date(),
                maxConnections: 125,
                maxConnectionsUpdatedAt: Date().addingTimeInterval(-14400)
            ),
            User(
                id: "user5",
                name: "伊藤健太",
                inviteCode: "CODE5",
                allowQRRegistration: true,
                createdAt: Date(),
                updatedAt: Date(),
                maxConnections: 118,
                maxConnectionsUpdatedAt: Date().addingTimeInterval(-18000)
            ),
            User(
                id: "user6",
                name: "渡辺愛",
                inviteCode: "CODE6",
                allowQRRegistration: true,
                createdAt: Date(),
                updatedAt: Date(),
                maxConnections: 112,
                maxConnectionsUpdatedAt: Date().addingTimeInterval(-21600)
            ),
            User(
                id: "user7",
                name: "山本大輔",
                inviteCode: "CODE7",
                allowQRRegistration: true,
                createdAt: Date(),
                updatedAt: Date(),
                maxConnections: 105,
                maxConnectionsUpdatedAt: Date().addingTimeInterval(-25200)
            ),
            User(
                id: "user8",
                name: "中村さくら",
                inviteCode: "CODE8",
                allowQRRegistration: true,
                createdAt: Date(),
                updatedAt: Date(),
                maxConnections: 98,
                maxConnectionsUpdatedAt: Date().addingTimeInterval(-28800)
            ),
            User(
                id: "user9",
                name: "小林翔太",
                inviteCode: "CODE9",
                allowQRRegistration: true,
                createdAt: Date(),
                updatedAt: Date(),
                maxConnections: 92,
                maxConnectionsUpdatedAt: Date().addingTimeInterval(-32400)
            ),
            User(
                id: "user10",
                name: "加藤結衣",
                inviteCode: "CODE10",
                allowQRRegistration: true,
                createdAt: Date(),
                updatedAt: Date(),
                maxConnections: 87,
                maxConnectionsUpdatedAt: Date().addingTimeInterval(-36000)
            ),
        ]
    }
}

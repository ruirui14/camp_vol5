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
                    ProgressView("読み込み中...")
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
                    Text("同接ランキング")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
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

#Preview {
    let authManager = AuthenticationManager()
    let userService = UserService.shared
    let heartbeatService = HeartbeatService.shared
    let vibrationService = VibrationService.shared

    let factory = ViewModelFactory(
        authenticationManager: authManager,
        userService: userService,
        heartbeatService: heartbeatService,
        vibrationService: vibrationService
    )

    return ConnectionsRankingView(viewModelFactory: factory)
        .environmentObject(factory)
}

// ViewModels/ConnectionsRankingViewModel.swift
// 同接数ランキング画面のビューモデル
// 最大接続数のランキングを取得・表示するロジックを管理

import Combine
import Foundation

@MainActor
class ConnectionsRankingViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var rankingUsers: [User] = []
    @Published var isLoadingMore = false
    @Published var hasMoreData = true

    // MARK: - Private Properties
    private let userService: UserServiceProtocol
    private let pageSize: Int
    private var currentPage = 0
    private var allUsers: [User] = []  // 全データをキャッシュ

    // MARK: - Initialization
    init(
        userService: UserServiceProtocol,
        pageSize: Int = 20
    ) {
        self.userService = userService
        self.pageSize = pageSize
        super.init()
    }

    // MARK: - Public Methods

    /// 初回ランキング読み込み
    func loadRanking() {
        let trace = PerformanceMonitor.shared.startTrace(
            PerformanceMonitor.UITrace.loadConnectionsRanking)

        isLoading = true
        clearError()
        currentPage = 0
        allUsers = []
        rankingUsers = []
        hasMoreData = true

        let startTime = Date()

        // 最大100件を取得してキャッシュ（初回ロードはキャッシュ利用）
        userService.getMaxConnectionsRanking(limit: 100, forceRefresh: false)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false

                    // UI読み込み時間を記録
                    let loadDuration = Date().timeIntervalSince(startTime)
                    if let trace = trace {
                        PerformanceMonitor.shared.incrementMetric(
                            trace,
                            key: "ui_load_duration_ms",
                            by: Int64(loadDuration * 1000)
                        )
                    }

                    PerformanceMonitor.shared.stopTrace(trace)

                    if case let .failure(error) = completion {
                        self?.handleError(error)
                        print("❌ ランキング画面読み込みエラー: \(error.localizedDescription)")
                    } else {
                        print(
                            "✅ ランキング画面読み込み完了 (所要時間: \(String(format: "%.2f", loadDuration * 1000))ms)"
                        )
                    }
                },
                receiveValue: { [weak self] users in
                    guard let self = self else { return }

                    self.allUsers = users
                    self.loadNextPage()

                    // 取得件数をメトリクスに記録
                    if let trace = trace {
                        PerformanceMonitor.shared.setAttribute(
                            trace,
                            key: "result_count",
                            value: String(users.count)
                        )
                    }

                    print("✅ ランキング取得成功: \(users.count)件（初回表示: \(self.rankingUsers.count)件）")
                }
            )
            .store(in: &cancellables)
    }

    /// 次のページを読み込む
    func loadNextPage() {
        guard hasMoreData, !isLoadingMore else { return }

        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, allUsers.count)

        guard startIndex < allUsers.count else {
            hasMoreData = false
            return
        }

        let nextPageUsers = Array(allUsers[startIndex..<endIndex])
        rankingUsers.append(contentsOf: nextPageUsers)
        currentPage += 1

        // 全データを表示し終わったか確認
        if rankingUsers.count >= allUsers.count {
            hasMoreData = false
        }

        print(
            "📄 ページ\(currentPage)読み込み: \(nextPageUsers.count)件追加（合計: \(rankingUsers.count)/\(allUsers.count)件）"
        )
    }

    /// スクロールで追加読み込みをトリガー
    func loadMoreIfNeeded(currentItem: User?) {
        guard let currentItem = currentItem else {
            loadNextPage()
            return
        }

        let thresholdIndex = rankingUsers.index(rankingUsers.endIndex, offsetBy: -5)
        if let currentIndex = rankingUsers.firstIndex(where: { $0.id == currentItem.id }),
            currentIndex >= thresholdIndex
        {
            loadNextPage()
        }
    }

    /// リフレッシュ（強制的に最新データを取得）
    func refresh() {
        let trace = PerformanceMonitor.shared.startTrace(
            PerformanceMonitor.UITrace.loadConnectionsRanking)

        isLoading = true
        clearError()
        currentPage = 0
        allUsers = []
        rankingUsers = []
        hasMoreData = true

        let startTime = Date()

        // 強制リフレッシュ：キャッシュをスキップして最新データを取得
        userService.getMaxConnectionsRanking(limit: 100, forceRefresh: true)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false

                    let loadDuration = Date().timeIntervalSince(startTime)
                    if let trace = trace {
                        PerformanceMonitor.shared.incrementMetric(
                            trace,
                            key: "ui_load_duration_ms",
                            by: Int64(loadDuration * 1000)
                        )
                    }

                    PerformanceMonitor.shared.stopTrace(trace)

                    if case let .failure(error) = completion {
                        self?.handleError(error)
                        print("❌ ランキングリフレッシュエラー: \(error.localizedDescription)")
                    } else {
                        print(
                            "✅ ランキングリフレッシュ完了 (所要時間: \(String(format: "%.2f", loadDuration * 1000))ms)"
                        )
                    }
                },
                receiveValue: { [weak self] users in
                    guard let self = self else { return }

                    self.allUsers = users
                    self.loadNextPage()

                    if let trace = trace {
                        PerformanceMonitor.shared.setAttribute(
                            trace,
                            key: "result_count",
                            value: String(users.count)
                        )
                    }

                    print("🔄 ランキングリフレッシュ成功: \(users.count)件（初回表示: \(self.rankingUsers.count)件）")
                }
            )
            .store(in: &cancellables)
    }
}

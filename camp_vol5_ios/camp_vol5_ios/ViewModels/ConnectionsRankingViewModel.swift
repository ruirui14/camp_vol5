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
    private let maxItems = 100  // 最大取得件数

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
        loadRankingData(action: "初回読み込み")
    }

    /// 次のページを読み込む
    func loadNextPage() {
        guard hasMoreData, !isLoadingMore else { return }

        // 最大件数に達したらロードしない
        if rankingUsers.count >= maxItems {
            hasMoreData = false
            return
        }

        isLoadingMore = true

        let offset = rankingUsers.count
        let limit = min(pageSize, maxItems - offset)

        print("📄 次のページを読み込み中: offset=\(offset), limit=\(limit)")

        userService.getMaxConnectionsRanking(offset: offset, limit: limit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingMore = false

                    if case let .failure(error) = completion {
                        self?.handleError(error)
                        print("❌ 次のページ読み込みエラー: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] users in
                    guard let self = self else { return }

                    self.rankingUsers.append(contentsOf: users)

                    // データが取得件数未満なら、これ以上データがない
                    if users.count < limit {
                        self.hasMoreData = false
                    }

                    // 最大件数に達したか確認
                    if self.rankingUsers.count >= self.maxItems {
                        self.hasMoreData = false
                    }

                    print(
                        "✅ 次のページ読み込み成功: \(users.count)件追加（合計: \(self.rankingUsers.count)件）"
                    )
                }
            )
            .store(in: &cancellables)
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

    /// リフレッシュ（最新データを取得）
    func refresh() {
        loadRankingData(action: "リフレッシュ")
    }

    // MARK: - Private Methods

    /// ランキングデータの共通読み込みロジック
    private func loadRankingData(action: String) {
        let trace = PerformanceMonitor.shared.startTrace(
            PerformanceMonitor.UITrace.loadConnectionsRanking)

        isLoading = true
        clearError()
        rankingUsers = []
        hasMoreData = true

        let startTime = Date()

        // 最初のページを取得
        userService.getMaxConnectionsRanking(offset: 0, limit: pageSize)
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
                        print("❌ ランキング\(action)エラー: \(error.localizedDescription)")
                    } else {
                        print(
                            "✅ ランキング\(action)完了 (所要時間: \(String(format: "%.2f", loadDuration * 1000))ms)"
                        )
                    }
                },
                receiveValue: { [weak self] users in
                    guard let self = self else { return }

                    self.rankingUsers = users

                    // データが取得件数未満なら、これ以上データがない
                    if users.count < self.pageSize {
                        self.hasMoreData = false
                    }

                    // 取得件数をメトリクスに記録
                    if let trace = trace {
                        PerformanceMonitor.shared.setAttribute(
                            trace,
                            key: "result_count",
                            value: String(users.count)
                        )
                    }

                    print("✅ ランキング\(action)成功: \(users.count)件")
                }
            )
            .store(in: &cancellables)
    }
}

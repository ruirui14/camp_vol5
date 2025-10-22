// ViewModels/StreamViewModel.swift
// 配信視聴画面のViewModel - MVVMアーキテクチャに従い、
// HeartbeatDetailViewModelの心拍データを共有して使用

import Combine
import Foundation

/// 配信視聴画面のViewModel
class StreamViewModel: BaseViewModel {
    // MARK: - Published Properties

    /// 配信URL（セッション内のみ保持）
    @Published var streamUrl: String = ""

    /// 現在のBPM
    @Published var currentBpm: Int = 0

    /// URL入力シートの表示状態
    @Published var showingUrlInput: Bool = false

    // MARK: - Private Properties

    private let heartbeatDetailViewModel: HeartbeatDetailViewModel
    private var heartbeatObserver: AnyCancellable?

    // MARK: - Initialization

    init(heartbeatDetailViewModel: HeartbeatDetailViewModel) {
        self.heartbeatDetailViewModel = heartbeatDetailViewModel
        super.init()
    }

    deinit {
        // deinitはメインアクター外で呼ばれる可能性があるため、
        // クリーンアップは手動でstopMonitoring()を呼び出すことで行う
        heartbeatObserver?.cancel()
        heartbeatObserver = nil
    }

    // MARK: - Public Methods

    /// 心拍監視を開始（HeartbeatDetailViewModelのデータを監視）
    func startMonitoring() {
        heartbeatObserver = heartbeatDetailViewModel.$currentHeartbeat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartbeat in
                self?.currentBpm = heartbeat?.bpm ?? 0
            }
    }

    /// 心拍監視を停止
    func stopMonitoring() {
        heartbeatObserver?.cancel()
        heartbeatObserver = nil
    }
}

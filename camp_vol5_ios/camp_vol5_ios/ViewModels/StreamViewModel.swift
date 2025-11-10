// ViewModels/StreamViewModel.swift
// 配信視聴画面のViewModel - MVVMアーキテクチャに従い、
// HeartbeatDetailViewModelの心拍データを共有して使用
// UI状態管理、ハートアニメーション位置管理を担当

import Combine
import Foundation
import SwiftUI

/// 配信視聴画面のViewModel
class StreamViewModel: BaseViewModel {
    // MARK: - Published Properties

    /// 配信URL（セッション内のみ保持）
    @Published var streamUrl: String = ""

    /// 現在のBPM
    @Published var currentBpm: Int = 0

    /// URL入力シートの表示状態
    @Published var showingUrlInput: Bool = false

    /// ハートの現在のオフセット位置
    @Published var heartOffset: CGSize = .zero

    /// ハートのドラッグ前のオフセット位置
    @Published var lastHeartOffset: CGSize = .zero

    /// フルスクリーンモードの状態
    @Published var isFullscreen: Bool = false

    /// コントロール表示状態
    @Published var showControls: Bool = false

    /// ビデオリロード用のID（変更時にビデオが再読み込みされる）
    @Published var videoReloadID: UUID = UUID()

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

    // MARK: - Public Methods - Monitoring

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

    // MARK: - Public Methods - UI State Management

    /// ハートの位置をリセット
    func resetHeartPosition() {
        heartOffset = .zero
        lastHeartOffset = .zero
    }

    /// ビデオをリロード
    func reloadVideo() {
        videoReloadID = UUID()
    }

    /// フルスクリーンモードを有効化
    func enterFullscreen() {
        isFullscreen = true
        showControls = false
    }

    /// フルスクリーンモードを無効化
    func exitFullscreen() {
        isFullscreen = false
        showControls = false
    }

    /// コントロール表示をトグル
    func toggleControls() {
        showControls.toggle()
    }

    /// ハートのドラッグ位置を更新
    /// - Parameter translation: ドラッグの移動量
    func updateHeartOffset(translation: CGSize) {
        heartOffset = CGSize(
            width: lastHeartOffset.width + translation.width,
            height: lastHeartOffset.height + translation.height
        )
    }

    /// ハートのドラッグ終了時の位置を保存
    func saveHeartOffset() {
        lastHeartOffset = heartOffset
    }
}

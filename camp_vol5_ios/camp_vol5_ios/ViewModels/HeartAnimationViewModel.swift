// ViewModels/HeartAnimationViewModel.swift
// ハートアニメーション制御用のViewModel - リアルな心拍パターンを再現

import Combine
import Foundation

@MainActor
class HeartAnimationViewModel: ObservableObject {
    @Published var currentBPM: Int = 0
    @Published var isSimulating: Bool = false

    // ★ Viewに「鼓動せよ！」と通知するための仕組み
    let heartbeatSubject = PassthroughSubject<Void, Never>()

    // ★ 心拍補間システム
    private var beatTimer: Timer?
    private var baseInterval: Double = 0.0
    private var lastBeatTime: Date = .init()

    // ★ HRV (心拍変動) パラメータ
    private let hrvVariabilityPercent: Double = 3.0  // ±3%の変動

    /// 心拍シミュレーションを開始
    func startSimulation(bpm: Int) {
        guard bpm > 0, bpm <= 220 else { return }

        // 同じBPMの場合は何もしない
        if currentBPM == bpm, isSimulating { return }

        // 古いタイマーを停止
        stopSimulation()

        currentBPM = bpm
        isSimulating = true

        // 1. 基本インターバルを計算 (60秒 ÷ BPM)
        baseInterval = 60.0 / Double(bpm)
        lastBeatTime = Date()

        // 2. 初回の鼓動を即座に実行
        triggerHeartbeat()

        // 3. 次の鼓動をスケジュール
        scheduleNextBeat()
    }

    /// 心拍シミュレーションを停止
    func stopSimulation() {
        beatTimer?.invalidate()
        beatTimer = nil
        currentBPM = 0
        isSimulating = false
    }

    /// 一回だけ鼓動させる（手動トリガー用）
    func triggerSingleBeat() {
        triggerHeartbeat()
    }

    // MARK: - Private Methods

    /// 次の鼓動をスケジュール（HRV変動付き）
    private func scheduleNextBeat() {
        guard currentBPM > 0, isSimulating else { return }

        // HRV（心拍変動）を適用
        let variationFactor = generateHRVVariation()
        let actualInterval = baseInterval * variationFactor

        // 高精度タイマーでスケジュール
        beatTimer = Timer.scheduledTimer(withTimeInterval: actualInterval, repeats: false) {
            [weak self] _ in
            self?.timerFired()
        }
    }

    /// タイマー発火時の処理（nonisolated）
    private nonisolated func timerFired() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.triggerHeartbeat()
            self.scheduleNextBeat()  // 再帰的に次をスケジュール
        }
    }

    /// HRV（心拍変動）を生成
    private func generateHRVVariation() -> Double {
        let randomVariation =
            Double.random(in: -hrvVariabilityPercent...hrvVariabilityPercent) / 100.0
        return 1.0 + randomVariation
    }

    /// 鼓動イベントを発生
    private func triggerHeartbeat() {
        let now = Date()
        lastBeatTime = now

        // Viewに鼓動を通知
        heartbeatSubject.send()
    }

    deinit {
        beatTimer?.invalidate()
        beatTimer = nil
    }
}

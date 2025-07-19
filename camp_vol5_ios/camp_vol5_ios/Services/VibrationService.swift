// VibrationService.swift
// 心拍BPMに応じて振動パターンを生成するサービス
// より心臓の鼓動に近い2段階の振動パターンを実現

import Foundation
import UIKit

class VibrationService: ObservableObject {
    static let shared = VibrationService()

    @Published var isVibrating = false
    private var vibrationTimer: Timer?

    private init() {}

    // MARK: - Public Methods

    /// BPMに基づいて心拍パターンの振動を開始
    /// - Parameter bpm: 1分間の心拍数
    func startHeartbeatVibration(bpm: Int) {
        stopVibration()

        guard bpm > 0 && bpm <= 300 else {
            print("⚠️ 無効なBPM値: \(bpm)")
            return
        }

        isVibrating = true
        let interval = 60.0 / Double(bpm)  // BPMから間隔を計算

        currentBPM = bpm
        print("🫀 心拍振動開始: \(bpm) BPM (間隔: \(String(format: "%.2f", interval))秒)")

        vibrationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
            [weak self] _ in
            self?.triggerHeartbeatPattern()
        }

        // 初回の振動を即座に実行
        triggerHeartbeatPattern()
    }

    /// 振動を停止
    func stopVibration() {
        isVibrating = false
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        currentBPM = 0
        print("⏹️ 心拍振動停止")
    }

    // MARK: - Private Methods

    /// 心拍の「ドクン」パターンを再現する振動
    private func triggerHeartbeatPattern() {
        // 1回目の振動（ドク）- 強い振動
        let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
        heavyImpact.prepare()  // パフォーマンス向上のため事前準備
        heavyImpact.impactOccurred()

        // 2回目の振動（ン）- 少し遅れて軽い振動
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
            mediumImpact.prepare()
            mediumImpact.impactOccurred()
        }
    }

    /// BPMの妥当性をチェック
    func isValidBPM(_ bpm: Int) -> Bool {
        return bpm >= 30 && bpm <= 220  // 一般的な人間の心拍数範囲
    }

    /// 現在の振動状態を取得
    func getVibrationStatus() -> String {
        return isVibrating ? "振動中" : "停止中"
    }

    /// 指定した継続時間だけ心拍振動を実行（一時的な振動用）
    /// - Parameters:
    ///   - bpm: 心拍数
    ///   - duration: 振動継続時間（秒）
    func startTemporaryHeartbeatVibration(bpm: Int, duration: TimeInterval) {
        startHeartbeatVibration(bpm: bpm)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopVibration()
        }
    }

    /// 現在のBPMを取得
    private(set) var currentBPM: Int = 0
}

// MARK: - Extensions

extension VibrationService {
    /// BPMカテゴリに応じた振動の強度を調整（将来の拡張用）
    private func getVibrationIntensityForBPM(_ bpm: Int) -> UIImpactFeedbackGenerator.FeedbackStyle
    {
        switch bpm {
        case 0..<60:
            return .light  // 低心拍数
        case 60..<100:
            return .medium  // 正常心拍数
        case 100..<140:
            return .heavy  // 高心拍数
        default:
            return .heavy  // 非常に高い心拍数
        }
    }
}

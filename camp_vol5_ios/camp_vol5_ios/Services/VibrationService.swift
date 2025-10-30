// VibrationService.swift
// 心拍BPMに応じて振動パターンを生成するサービス
// より心臓の鼓動に近い2段階の振動パターンを実現

import Combine
import Foundation
import UIKit

@MainActor
class VibrationService: ObservableObject, VibrationServiceProtocol {
    static let shared = VibrationService()

    @Published var isVibrating = false
    @Published var isEnabled = true  // 振動機能の有効/無効状態
    private var vibrationTimer: Timer?
    private var lastVibrationTime: Date?  // 最後の振動発生時刻
    private let minimumVibrationInterval: TimeInterval = 0.3  // 最小振動間隔（秒）
    private var pendingBPM: Int?  // 次のサイクルで適用する予定のBPM

    /// UIアニメーションと同期するためのパブリッシャー
    let heartbeatTrigger = PassthroughSubject<Void, Never>()

    private static let vibrationSettingKey = "vibration_enabled"

    private init() {
        // 保存されている振動設定を読み込む
        loadVibrationSetting()
    }

    // MARK: - Public Methods

    /// BPMに基づいて心拍パターンの振動を開始
    /// - Parameter bpm: 1分間の心拍数
    func startHeartbeatVibration(bpm: Int) {
        guard bpm > 0 && bpm <= 300 else {
            return
        }

        // 同じBPMの場合は何もしない
        if isVibrating && currentBPM == bpm {
            return
        }

        // 振動中で異なるBPMの場合は、次のサイクルで適用する
        if isVibrating && currentBPM != bpm {
            pendingBPM = bpm
            print("📱 BPM変更を予約: \(currentBPM) → \(bpm)")
            return
        }

        // 振動していない場合は即座に開始
        isVibrating = true
        currentBPM = bpm
        pendingBPM = nil

        let interval = 60.0 / Double(bpm)  // BPMから間隔を計算

        vibrationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                self?.triggerHeartbeatPattern()
            }
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
        pendingBPM = nil  // 保留中のBPM変更もクリア
        lastVibrationTime = nil  // クールダウンタイマーもリセット
    }

    // MARK: - Private Methods

    /// 心拍の「ドクン」パターンを再現する振動
    private func triggerHeartbeatPattern() {
        // クールダウン期間中は振動をスキップ
        if let lastTime = lastVibrationTime {
            let timeSinceLastVibration = Date().timeIntervalSince(lastTime)
            if timeSinceLastVibration < minimumVibrationInterval {
                return
            }
        }

        // 最後の振動時刻を更新
        lastVibrationTime = Date()

        // UIアニメーションのトリガーを送信
        heartbeatTrigger.send()

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

        // 振動完了後、保留中のBPM変更があれば適用
        checkAndApplyPendingBPMChange()
    }

    /// 保留中のBPM変更を適用
    private func checkAndApplyPendingBPMChange() {
        guard let newBPM = pendingBPM else { return }

        print("📱 BPM変更を適用: \(currentBPM) → \(newBPM)")

        // 現在のタイマーを停止
        vibrationTimer?.invalidate()
        vibrationTimer = nil

        // 新しいBPMでタイマーを再設定
        currentBPM = newBPM
        pendingBPM = nil

        let interval = 60.0 / Double(newBPM)
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                self?.triggerHeartbeatPattern()
            }
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

    /// 振動機能を有効化
    func enable() {
        isEnabled = true
        saveVibrationSetting()
    }

    /// 振動機能を無効化
    func disable() {
        isEnabled = false
        stopVibration()
        saveVibrationSetting()
    }

    /// 振動機能のON/OFFをトグル
    func toggleEnabled() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }

    /// 現在のBPMを取得
    private(set) var currentBPM: Int = 0

    // MARK: - Vibration Settings Persistence

    /// UserDefaultsから振動設定を読み込む
    private func loadVibrationSetting() {
        // キーが存在しない場合はtrueを返す（初回はデフォルトで有効）
        if UserDefaults.standard.object(forKey: Self.vibrationSettingKey) == nil {
            isEnabled = true
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: Self.vibrationSettingKey)
        }
        print("📱 Vibration setting loaded: \(isEnabled)")
    }

    /// UserDefaultsに振動設定を保存する
    private func saveVibrationSetting() {
        UserDefaults.standard.set(isEnabled, forKey: Self.vibrationSettingKey)
        print("💾 Vibration setting saved: \(isEnabled)")
    }
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

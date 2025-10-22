// Services/DeviceOrientationManager.swift
// デバイスの向き検知サービス - CoreMotionを使用して加速度センサーからデバイスの向きを検知
// 画面を下向きにした場合に自動でスリープモードに移行する機能を提供

import Combine
import CoreMotion
import Foundation

class DeviceOrientationManager: ObservableObject {
    static let shared = DeviceOrientationManager()

    @Published var isFaceDown: Bool = false
    @Published var autoSleepEnabled: Bool = false

    private let motionManager = CMMotionManager()
    private var cancellables = Set<AnyCancellable>()

    // 下向き判定のしきい値（z軸の加速度が0.9以上で下向きと判定）
    private let faceDownThreshold: Double = 0.9

    // 下向き状態が継続した時間を追跡（誤検知防止）
    private var faceDownStartTime: Date?
    private let faceDownDelaySeconds: TimeInterval = 1.0  // 1秒間下向きで確定

    private init() {
        loadSettings()
    }

    // MARK: - Public Methods

    /// 向き検知の開始
    func startMonitoring() {
        guard autoSleepEnabled else { return }
        guard !motionManager.isAccelerometerActive else { return }
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 0.5  // 0.5秒ごとに更新

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            guard error == nil else { return }

            self.handleAccelerometerUpdate(data)
        }
    }

    /// 向き検知の停止
    func stopMonitoring() {
        guard motionManager.isAccelerometerActive else { return }
        motionManager.stopAccelerometerUpdates()
        isFaceDown = false
        faceDownStartTime = nil
    }

    /// 設定の更新
    func updateSettings(autoSleepEnabled: Bool) {
        let wasEnabled = self.autoSleepEnabled
        self.autoSleepEnabled = autoSleepEnabled
        saveSettings()

        // 設定が変更された場合、監視状態を更新
        if autoSleepEnabled && !wasEnabled {
            startMonitoring()
        } else if !autoSleepEnabled && wasEnabled {
            stopMonitoring()
        }
    }

    // MARK: - Private Methods

    private func handleAccelerometerUpdate(_ data: CMAccelerometerData) {
        let zAcceleration = data.acceleration.z
        let isCurrentlyFaceDown = zAcceleration > faceDownThreshold

        if isCurrentlyFaceDown {
            // 下向き状態が開始した時刻を記録
            if faceDownStartTime == nil {
                faceDownStartTime = Date()
            }

            // 下向き状態が一定時間継続したら確定
            if let startTime = faceDownStartTime,
                Date().timeIntervalSince(startTime) >= faceDownDelaySeconds
            {
                if !isFaceDown {
                    isFaceDown = true
                }
            }
        } else {
            // 下向きでなくなったらリセット
            isFaceDown = false
            faceDownStartTime = nil
        }
    }

    private func saveSettings() {
        UserDefaults.standard.set(autoSleepEnabled, forKey: "autoSleepEnabled")
    }

    private func loadSettings() {
        autoSleepEnabled = UserDefaults.standard.bool(forKey: "autoSleepEnabled")
    }
}

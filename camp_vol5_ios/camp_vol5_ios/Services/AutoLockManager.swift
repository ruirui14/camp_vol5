import Combine
import Foundation
import UIKit

class AutoLockManager: ObservableObject {
    static let shared = AutoLockManager()

    @Published var autoLockDisabled: Bool = false
    @Published var autoLockDuration: TimeInterval = 900  // デフォルト15分
    @Published var remainingTime: TimeInterval = 0

    private var disableTimer: Timer?
    private var updateTimer: Timer?
    private var startTime: Date?

    // 利用可能な時間オプション（秒）
    // 5分, 10分, 15分, 30分, 45分, 1時間, 2時間
    let availableDurations: [TimeInterval] = [300, 600, 900, 1800, 2700, 3600, 7200]

    private init() {
        loadSettings()
    }

    // MARK: - Public Methods

    func enableAutoLockDisabling() {
        guard autoLockDisabled else { return }

        UIApplication.shared.isIdleTimerDisabled = true
        startTime = Date()
        remainingTime = autoLockDuration

        // 指定時間後に自動で無効化を解除
        disableTimer?.invalidate()
        disableTimer = Timer.scheduledTimer(withTimeInterval: autoLockDuration, repeats: false) {
            _ in
            DispatchQueue.main.async {
                self.disableAutoLockDisabling()
            }
        }

        // 残り時間を1分ごとに更新（UI負荷軽減）
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateRemainingTime()
            }
        }
    }

    func disableAutoLockDisabling() {
        UIApplication.shared.isIdleTimerDisabled = false
        disableTimer?.invalidate()
        disableTimer = nil
        updateTimer?.invalidate()
        updateTimer = nil
        remainingTime = 0
        startTime = nil
    }

    private func updateRemainingTime() {
        guard let startTime = startTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let newRemainingTime = max(0, autoLockDuration - elapsed)

        // 残り時間が1分以上変化した場合、または終了間近（2分以下）の場合のみ更新
        let timeDifference = abs(newRemainingTime - remainingTime)
        if timeDifference >= 60 || newRemainingTime <= 120 {
            remainingTime = newRemainingTime
        }
    }

    func updateSettings(autoLockDisabled: Bool, duration: TimeInterval) {
        self.autoLockDisabled = autoLockDisabled
        self.autoLockDuration = duration
        saveSettings()
    }

    func durationDisplayText(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return "\(Int(duration))秒"
        } else if duration < 3600 {
            return "\(Int(duration / 60))分"
        } else {
            return "\(Int(duration / 3600))時間"
        }
    }

    // MARK: - Private Methods

    private func saveSettings() {
        UserDefaults.standard.set(autoLockDisabled, forKey: "autoLockDisabled")
        UserDefaults.standard.set(autoLockDuration, forKey: "autoLockDuration")
    }

    private func loadSettings() {
        autoLockDisabled = UserDefaults.standard.bool(forKey: "autoLockDisabled")
        let savedDuration = UserDefaults.standard.double(forKey: "autoLockDuration")
        if savedDuration > 0 {
            autoLockDuration = savedDuration
        }
    }
}

// Views/Components/HeartbeatDetailStatusBar.swift
// 心拍詳細画面のステータス表示コンポーネント - 振動状態、自動ロック状態、最終更新時刻を表示
// SwiftUIベストプラクティスに従い、単一責任の原則を適用

import SwiftUI

struct HeartbeatDetailStatusBar: View {
    let isVibrationEnabled: Bool
    let isVibrating: Bool
    let vibrationStatus: String
    let autoLockDisabled: Bool
    let remainingTime: TimeInterval
    let isSleepMode: Bool
    let heartbeat: Heartbeat?

    var body: some View {
        VStack(spacing: 8) {
            // 振動状態表示
            if isVibrationEnabled {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isVibrating ? 1.5 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever(),
                            value: isVibrating
                        )

                    Text("心拍振動: \(vibrationStatus)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
            }

            // 自動ロック無効化残り時間
            if autoLockDisabled && remainingTime > 0 && !isSleepMode {
                HStack {
                    Image(systemName: "lock.slash")
                        .foregroundColor(.yellow)
                        .font(.caption)

                    Text("自動ロック無効: \(formatRemainingTime(remainingTime))")
                        .font(.caption)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
            }

            // 最終更新時刻
            if let heartbeat = heartbeat {
                Text("Last updated: \(heartbeat.timestamp, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
            } else {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
            }
        }
    }

    private func formatRemainingTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    HeartbeatDetailStatusBar(
        isVibrationEnabled: true,
        isVibrating: true,
        vibrationStatus: "アクティブ",
        autoLockDisabled: true,
        remainingTime: 300,
        isSleepMode: false,
        heartbeat: Heartbeat(userId: "test", bpm: 75, timestamp: Date())
    )
    .background(Color.black)
}
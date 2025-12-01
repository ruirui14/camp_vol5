// Views/HeartbeatDetail/HeartbeatDetailStatusBar.swift
// 心拍詳細画面のステータス表示コンポーネント - 振動状態、自動ロック状態、最終更新時刻を表示
// SwiftUIベストプラクティスに従い、単一責任の原則を適用
// モダンなグラスモルフィズムデザインを採用

import SwiftUI

struct HeartbeatDetailStatusBar: View {
    let autoLockDisabled: Bool
    let remainingTime: TimeInterval
    let isSleepMode: Bool
    let heartbeat: Heartbeat?
    let currentTime: Date

    // MARK: - Static Date Formatters
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()

    var body: some View {
        VStack(spacing: 12) {
            // 自動ロック無効化残り時間
            if autoLockDisabled && remainingTime > 0 && !isSleepMode {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("\(formatRemainingTime(remainingTime))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .simpleGlassCapsule()
            }

            // 最終更新時刻 - モダンなタイムスタンプ表示
            if let heartbeat = heartbeat, let timestamp = heartbeat.timestamp {
                HStack(spacing: 6) {
                    // 時計アイコン
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.3),
                                        Color.cyan.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 20, height: 20)

                        Image(systemName: "clock.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }

                    Text(relativeTimeString(from: timestamp))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .tracking(0.3)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
        }
    }

    private func formatRemainingTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // 相対時間を日本語で表示（"1分前"、"たった今"など）
    private func relativeTimeString(from date: Date) -> String {
        let interval = currentTime.timeIntervalSince(date)
        if interval < 10 {
            return "たった今"
        } else if interval < 60 {
            return "\(Int(interval))秒前"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)時間前"
        } else {
            // 1日以上経過している場合は日時を表示
            return Self.longDateFormatter.string(from: date)
        }
    }
}

#Preview {
    HeartbeatDetailStatusBar(
        autoLockDisabled: true,
        remainingTime: 300,
        isSleepMode: false,
        heartbeat: Heartbeat(userId: "test", bpm: 75, timestamp: Date()),
        currentTime: Date()
    )
    .background(Color.black)
}

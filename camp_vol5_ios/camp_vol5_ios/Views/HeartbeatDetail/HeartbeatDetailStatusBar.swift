// Views/HeartbeatDetail/HeartbeatDetailStatusBar.swift
// 心拍詳細画面のステータス表示コンポーネント - 振動状態、自動ロック状態、最終更新時刻を表示
// SwiftUIベストプラクティスに従い、単一責任の原則を適用
// モダンなグラスモルフィズムデザインを採用

import SwiftUI

struct HeartbeatDetailStatusBar: View {
    let isVibrationEnabled: Bool
    let isVibrating: Bool
    let vibrationStatus: String
    let autoLockDisabled: Bool
    let remainingTime: TimeInterval
    let isSleepMode: Bool
    let heartbeat: Heartbeat?

    @State private var pulseAnimation = false

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
            // 振動状態表示 - モダンなカプセル型デザイン
            if isVibrationEnabled {
                HStack(spacing: 8) {
                    // 心拍アイコンとパルスアニメーション
                    ZStack {
                        // 外側のパルス効果
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.6), Color.pink.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                            .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                            .opacity(pulseAnimation ? 0 : 0.8)

                        // メインアイコン
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.red, Color.pink],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    }
                    .onAppear {
                        if isVibrating {
                            withAnimation(
                                .easeInOut(duration: 1.2)
                                    .repeatForever(autoreverses: false)
                            ) {
                                pulseAnimation = true
                            }
                        }
                    }

                    Text(vibrationStatus)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .vibrationStatusGlassCapsule()
            }

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

            // 最終更新時刻 - エレガントなタイムスタンプ表示
            if let heartbeat = heartbeat {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(relativeTimeString(from: heartbeat.timestamp))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .statusGlassCapsule()
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange.opacity(0.8))

                    Text("データなし")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .simpleGlassCapsule()
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
        let now = Date()
        let interval = now.timeIntervalSince(date)

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

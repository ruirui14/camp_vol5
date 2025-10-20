// Views/Settings/HeartbeatSettingsView.swift
// 心拍データ設定画面 - 現在の心拍情報の表示と更新機能を提供
// SwiftUIベストプラクティスに従い、アニメーションと状態管理を実装

import SwiftUI

struct HeartbeatSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("あなたの心拍") {
                HeartbeatContent(viewModel: viewModel)
            }

            Section(" リスナー情報") {
                ConnectionCountRow(count: viewModel.connectionCount)
            }
        }
        .navigationTitle("心拍データ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HeartbeatContent: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(spacing: 20) {
            // ハートアニメーション表示
            HeartbeatDisplaySection(heartbeat: viewModel.currentHeartbeat)

            // 更新ボタン
            HeartbeatRefreshButton {
                viewModel.refreshHeartbeat()
            }
        }
    }
}

struct HeartbeatDisplaySection: View {
    let heartbeat: Heartbeat?

    var body: some View {
        VStack(spacing: 12) {
            if let heartbeat = heartbeat {
                ActiveHeartbeatView(heartbeat: heartbeat)
            } else {
                InactiveHeartbeatView()
            }
        }
    }
}

struct ActiveHeartbeatView: View {
    let heartbeat: Heartbeat

    var body: some View {
        VStack(spacing: 8) {
            HeartAnimationView(
                bpm: heartbeat.bpm,
                heartSize: 120,
                showBPM: true,
                enableHaptic: true,
                heartColor: .red
            )
            .frame(height: 140)

            Text("更新: \(formattedTime(heartbeat.timestamp))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct InactiveHeartbeatView: View {
    var body: some View {
        VStack(spacing: 8) {
            HeartAnimationView(
                bpm: 0,
                heartSize: 120,
                showBPM: true,
                enableHaptic: false,
                heartColor: .gray
            )
            .frame(height: 140)

            Text("データなし")
                .foregroundColor(.secondary)
        }
    }
}

struct HeartbeatRefreshButton: View {
    let action: () -> Void

    var body: some View {
        Button("更新") {
            action()
        }
        .buttonStyle(.bordered)
    }
}

struct ConnectionCountRow: View {
    let count: Int

    var body: some View {
        HStack {
            Label("現在あなたの心拍を聞いている人数", systemImage: "person.2.fill")
                .foregroundColor(.primary)

            Spacer()

            Text("\(count)")
                .font(.headline)
                // swiftlint:disable:next empty_count
                .foregroundColor(count > 0 ? .green : .secondary)
        }
    }
}

#Preview {
    NavigationStack {
        HeartbeatSettingsView(
            viewModel: SettingsViewModel(authenticationManager: AuthenticationManager())
        )
    }
}

// Views/Settings/AutoLockSettingsView.swift
// 自動ロック設定画面 - iOSの自動ロック機能の制御設定を提供
// SwiftUIベストプラクティスに従い、設定の変更と状態管理を実装

import SwiftUI

struct AutoLockSettingsView: View {
    @ObservedObject var autoLockManager: AutoLockManager

    var body: some View {
        Form {
            Section(
                header: Text("自動ロック設定"),
                footer: AutoLockFooterText(isDisabled: autoLockManager.autoLockDisabled)
            ) {
                AutoLockToggleSection(autoLockManager: autoLockManager)

                if autoLockManager.autoLockDisabled {
                    AutoLockDurationPicker(autoLockManager: autoLockManager)
                }
            }
        }
        .navigationTitle("自動ロック")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: autoLockManager.autoLockDisabled) { isDisabled in
            autoLockManager.updateSettings(
                autoLockDisabled: isDisabled,
                duration: autoLockManager.autoLockDuration
            )
        }
        .onChange(of: autoLockManager.autoLockDuration) { duration in
            autoLockManager.updateSettings(
                autoLockDisabled: autoLockManager.autoLockDisabled,
                duration: duration
            )
        }
    }
}

struct AutoLockToggleSection: View {
    @ObservedObject var autoLockManager: AutoLockManager

    var body: some View {
        Toggle("自動ロックを無効にする", isOn: $autoLockManager.autoLockDisabled)
    }
}

struct AutoLockDurationPicker: View {
    @ObservedObject var autoLockManager: AutoLockManager

    var body: some View {
        Picker("無効化時間", selection: $autoLockManager.autoLockDuration) {
            ForEach(autoLockManager.availableDurations, id: \.self) { duration in
                Text(autoLockManager.durationDisplayText(duration))
                    .tag(duration)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
}

struct AutoLockFooterText: View {
    let isDisabled: Bool

    var body: some View {
        Text(
            isDisabled
                ? "指定した時間の間、iOSの自動ロックが無効になります。"
                : "iOSの通常の自動ロック設定が適用されます。"
        )
    }
}

#Preview {
    NavigationView {
        AutoLockSettingsView(autoLockManager: AutoLockManager.shared)
    }
}
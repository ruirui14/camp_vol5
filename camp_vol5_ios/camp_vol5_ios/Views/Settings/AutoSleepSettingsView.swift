// Views/Settings/AutoSleepSettingsView.swift
// 画面自動OFF設定画面 - デバイスの向き検知による自動スリープ機能の設定を提供
// SwiftUIベストプラクティスに従い、設定の変更と状態管理を実装

import SwiftUI

struct AutoSleepSettingsView: View {
    @StateObject private var orientationManager = DeviceOrientationManager.shared

    var body: some View {
        Form {
            Section(
                header: Text("画面自動OFF設定"),
                footer: Text("有効にすると、スマホが下を向いた時に自動で画面が黒くなります。画面をタップすると元に戻ります。")
            ) {
                Toggle("画面自動OFFを有効にする", isOn: $orientationManager.autoSleepEnabled)
            }
        }
        .navigationTitle("画面自動OFF")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: orientationManager.autoSleepEnabled) { _, enabled in
            orientationManager.updateSettings(autoSleepEnabled: enabled)
        }
    }
}

#Preview {
    NavigationStack {
        AutoSleepSettingsView()
    }
}

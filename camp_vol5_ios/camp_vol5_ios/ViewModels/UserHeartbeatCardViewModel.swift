// ViewModels/UserHeartbeatCardViewModel.swift
// UserHeartbeatCardのViewModel
// ユーザー情報と心拍データの表示ロジックを管理

import Combine
import SwiftUI

class UserHeartbeatCardViewModel: ObservableObject {
    @Published var displayName: String = "プレビュー"
    @Published var displayBPM: String = ""
    @Published var customBackgroundImage: UIImage?

    private let userWithHeartbeat: UserWithHeartbeat?

    init(userWithHeartbeat: UserWithHeartbeat? = nil) {
        self.userWithHeartbeat = userWithHeartbeat
        updateDisplayData()
    }

    init(customBackgroundImage: UIImage?, displayName: String?, displayBPM: String?) {
        self.userWithHeartbeat = nil
        self.customBackgroundImage = customBackgroundImage
        self.displayName = displayName ?? "プレビュー"
        self.displayBPM = displayBPM ?? ""
    }

    init(userWithHeartbeat: UserWithHeartbeat, customBackgroundImage: UIImage?) {
        self.userWithHeartbeat = userWithHeartbeat
        self.customBackgroundImage = customBackgroundImage
        updateDisplayData()
    }

    private func updateDisplayData() {
        guard let userWithHeartbeat = userWithHeartbeat else { return }

        displayName = userWithHeartbeat.user.name

        if let heartbeat = userWithHeartbeat.heartbeat {
            displayBPM = "\(heartbeat.bpm)"
        } else {
            displayBPM = ""
        }
    }

    func setCustomBackgroundImage(_ image: UIImage?) {
        customBackgroundImage = image
    }
}

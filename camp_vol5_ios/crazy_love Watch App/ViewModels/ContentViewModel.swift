import Combine
import Foundation
import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var currentHeartRate: Int = 0
    @Published var isBeating: Bool = false
    @ObservedObject var watchManager: WatchHeartRateManager

    private var cancellables = Set<AnyCancellable>()

    init() {
        watchManager = WatchHeartRateManager.shared
        setupBindings()
    }

    private func setupBindings() {
        watchManager.heartbeatSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.triggerHeartbeat()
            }
            .store(in: &cancellables)

        // currentUserの変更を監視
        watchManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
            }
            .store(in: &cancellables)
    }

    private func triggerHeartbeat() {
        isBeating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isBeating = false
        }
    }

    func onAppear() {
        watchManager.setup()
    }

    func onDisappear() {
        watchManager.cleanup()
    }

    func toggleSending() {
        if watchManager.isSending {
            watchManager.stopSending()
        } else {
            watchManager.startSending()
        }
    }

    func reconnect() {
        watchManager.reconnect()
    }

    var heartRateStatusColor: Color {
        switch watchManager.heartRateDetectionStatus {
        case "心拍数正常検知中":
            return .green
        case "心拍数未検知", "異常値検知":
            return .red
        case "心拍数検知待機中", "監視開始中":
            return .orange
        default:
            return .secondary
        }
    }
}

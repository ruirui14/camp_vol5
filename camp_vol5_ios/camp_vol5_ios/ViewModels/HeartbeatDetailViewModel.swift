// ViewModels/HeartbeatDetailViewModel.swift
// 心拍詳細画面のビューモデル - MVVM設計パターンに従いビジネスロジックを集約
// Viewからデータ取得、監視制御、エラーハンドリングを分離

import Combine
import Foundation
import SwiftUI

@MainActor
class HeartbeatDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var currentHeartbeat: Heartbeat?
    @Published var isMonitoring: Bool = false
    @Published var errorMessage: String?
    @Published var isVibrationEnabled: Bool = true
    @Published var isSleepMode: Bool = false

    // MARK: - Private Properties
    private let userId: String
    private var cancellables = Set<AnyCancellable>()
    private var heartbeatSubscription: AnyCancellable?

    // MARK: - Dependencies
    private let userService: UserService
    private let heartbeatService: HeartbeatService
    private let vibrationService: VibrationService

    // MARK: - Computed Properties
    var hasValidHeartbeat: Bool {
        guard let heartbeat = currentHeartbeat else { return false }
        return vibrationService.isValidBPM(heartbeat.bpm)
    }

    // MARK: - Initialization
    init(
        userId: String,
        userService: UserService = UserService.shared,
        heartbeatService: HeartbeatService = HeartbeatService.shared,
        vibrationService: VibrationService = VibrationService.shared
    ) {
        self.userId = userId
        self.userService = userService
        self.heartbeatService = heartbeatService
        self.vibrationService = vibrationService

        print("HeartbeatDetailViewModel init with userId: \(userId)")
        loadUserInfo()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        startContinuousMonitoring()
        enableVibrationIfNeeded()
    }

    func stopMonitoring() {
        stopContinuousMonitoring()
        disableVibration()
    }

    func toggleVibration() {
        isVibrationEnabled.toggle()

        if isVibrationEnabled {
            enableVibrationIfNeeded()
        } else {
            disableVibration()
        }
    }

    func toggleSleepMode() {
        isSleepMode.toggle()
    }

    func refreshData() {
        refreshHeartbeat()
    }

    // MARK: - Private Methods

    private func loadUserInfo() {
        userService.getUser(uid: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] user in
                    self?.user = user
                }
            )
            .store(in: &cancellables)
    }

    private func startContinuousMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        clearError()

        heartbeatSubscription = heartbeatService.subscribeToHeartbeat(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartbeat in
                self?.handleHeartbeatUpdate(heartbeat)
            }
    }

    private func stopContinuousMonitoring() {
        isMonitoring = false
        heartbeatSubscription?.cancel()
        heartbeatSubscription = nil
        heartbeatService.unsubscribeFromHeartbeat(userId: userId)
    }

    private func refreshHeartbeat() {
        heartbeatService.getHeartbeatOnce(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] heartbeat in
                    self?.handleHeartbeatUpdate(heartbeat)
                }
            )
            .store(in: &cancellables)
    }

    private func handleHeartbeatUpdate(_ heartbeat: Heartbeat?) {
        currentHeartbeat = heartbeat
        updateVibrationBasedOnHeartbeat()
    }

    private func updateVibrationBasedOnHeartbeat() {
        guard isVibrationEnabled else { return }

        if hasValidHeartbeat, let bpm = currentHeartbeat?.bpm {
            vibrationService.startHeartbeatVibration(bpm: bpm)
        } else {
            vibrationService.stopVibration()
        }
    }

    private func enableVibrationIfNeeded() {
        if hasValidHeartbeat, let bpm = currentHeartbeat?.bpm {
            vibrationService.startHeartbeatVibration(bpm: bpm)
        } else if currentHeartbeat == nil {
            // データがない場合は手動で更新を試みる
            refreshHeartbeat()
        }
    }

    private func disableVibration() {
        vibrationService.stopVibration()
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Lifecycle
    deinit {
        stopMonitoring()
    }
}

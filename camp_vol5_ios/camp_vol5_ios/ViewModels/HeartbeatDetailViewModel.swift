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
    private var mockDataTimer: Timer?

    // Mock Mode
    var useMockData: Bool = true // ダミーデータを使用するかどうか

    // MARK: - Dependencies
    private let userService: UserServiceProtocol
    private let heartbeatService: HeartbeatServiceProtocol
    private let vibrationService: VibrationServiceProtocol

    // MARK: - Computed Properties
    var hasValidHeartbeat: Bool {
        guard let heartbeat = currentHeartbeat else { return false }
        return vibrationService.isValidBPM(heartbeat.bpm)
    }

    // MARK: - Initialization
    init(
        userId: String,
        userService: UserServiceProtocol = UserService.shared,
        heartbeatService: HeartbeatServiceProtocol = HeartbeatService.shared,
        vibrationService: VibrationServiceProtocol = VibrationService.shared
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
        if useMockData {
            startMockDataGeneration()
        } else {
            startContinuousMonitoring()
        }
        enableVibrationIfNeeded()
    }

    func stopMonitoring() {
        if useMockData {
            stopMockDataGeneration()
        } else {
            stopContinuousMonitoring()
        }
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

    // MARK: - Mock Data Generation

    /// ダミーデータの生成を開始（80〜100のランダムな心拍数を1秒ごとに更新）
    private func startMockDataGeneration() {
        guard !isMonitoring else { return }

        isMonitoring = true
        clearError()

        // 初回データを即座に生成
        generateMockHeartbeat()

        // 2秒ごとに新しいダミーデータを生成
        mockDataTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.generateMockHeartbeat()
            }
        }
    }

    /// ダミーデータの生成を停止
    private func stopMockDataGeneration() {
        isMonitoring = false
        mockDataTimer?.invalidate()
        mockDataTimer = nil
    }

    /// 重み付けされたランダムな心拍データを生成
    /// - 75~85: 80% (8割)
    /// - 86~90: 15% (1.5割)
    /// - 91~95: 5% (0.5割)
    private func generateMockHeartbeat() {
        let randomBpm = generateWeightedRandomBPM()
        let mockHeartbeat = Heartbeat(userId: userId, bpm: randomBpm, timestamp: Date())
        handleHeartbeatUpdate(mockHeartbeat)
    }

    /// 重み付けされたランダムなBPM値を生成
    private func generateWeightedRandomBPM() -> Int {
        let random = Double.random(in: 0..<1.0)

        if random < 0.80 {
            // 80%の確率で75~85
            return Int.random(in: 75...85)
        } else if random < 0.95 {
            // 15%の確率で86~90
            return Int.random(in: 86...90)
        } else {
            // 5%の確率で91~95
            return Int.random(in: 91...95)
        }
    }

    // MARK: - Lifecycle
    deinit {
        // Note: stopMonitoring() should be called from view lifecycle (onDisappear)
        // to ensure proper MainActor context
    }
}

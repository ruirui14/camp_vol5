import Combine
import Foundation
import HealthKit
import WatchConnectivity

class WatchHeartRateManager: NSObject, ObservableObject {
    static let shared = WatchHeartRateManager()

    @Published var currentHeartRate: Int = 0
    @Published var isSending: Bool = false
    @Published var sentCount: Int = 0
    @Published var isConnected: Bool = false
    @Published var currentUser: HeartUser?
    @Published var isMonitoringHeartRate: Bool = false
    @Published var isStarting: Bool = false
    @Published var receivedDataCount: Int = 0
    @Published var heartRateDetectionStatus: String = "待機中"

    let heartbeatSubject = PassthroughSubject<Void, Never>()
    private var healthStore = HKHealthStore()
    private var wcSession: WCSession?
    private var sendingTimer: Timer?
    private var workoutSession: HKWorkoutSession?
    private var lastHeartRateUpdateTime: Date?
    private var heartRateTimeoutTimer: Timer?
    // 停止用
    private let heartRateTimeout: TimeInterval = 15.0
    private var consecutiveSendSkips: Int = 0
    private let maxConsecutiveSendSkips: Int = 5

    private override init() {
        super.init()
        restoreUserFromDefaults()
    }

    func setup() {
        setupWatchConnectivity()

        // 初期権限チェック
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let initialAuthStatus = healthStore.authorizationStatus(for: heartRateType)

        // 権限要求を強制実行
        requestHealthKitPermission()

        // 少し遅れて再度チェック
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let updatedAuthStatus = self.healthStore.authorizationStatus(for: heartRateType)
        }
    }

    func cleanup() {
        stopSending()
        heartRateTimeoutTimer?.invalidate()
    }

    func reconnect() {
        wcSession?.activate()
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }

    private func requestHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.heartRateDetectionStatus = "HealthKit利用不可"
            }
            return
        }

        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
        ]

        // 共有権限も要求（一部のヘルスデータには必要）
        let typesToShare: Set = [
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) {
            success, error in

            DispatchQueue.main.async {
                if let error = error {
                    self.heartRateDetectionStatus = "HealthKit権限エラー: \(error.localizedDescription)"
                } else if success {
                    // 実際の権限状態を再確認
                    let heartRateAuth = self.healthStore.authorizationStatus(
                        for: HKObjectType.quantityType(forIdentifier: .heartRate)!)
                    let workoutAuth = self.healthStore.authorizationStatus(
                        for: HKObjectType.workoutType())

                    switch heartRateAuth {
                    case .sharingAuthorized:
                        self.heartRateDetectionStatus = "HealthKit権限OK"
                    case .sharingDenied:
                        self.heartRateDetectionStatus =
                            "心拍数権限が拒否されました（Watchアプリの設定→プライバシー→ヘルスケアで許可してください）"
                    case .notDetermined:
                        self.heartRateDetectionStatus =
                            "心拍数権限が未設定です（Watchアプリの設定→プライバシー→ヘルスケアで設定してください）"
                    @unknown default:
                        self.heartRateDetectionStatus = "権限状態不明"
                    }
                } else {
                    self.heartRateDetectionStatus = "HealthKit権限が拒否されました"
                }
            }
        }
    }

    private func saveUserToDefaults(_ user: HeartUser) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentWatchUser")
        }
    }

    private func restoreUserFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: "currentWatchUser") {
            if let user = try? JSONDecoder().decode(HeartUser.self, from: data) {
                DispatchQueue.main.async {
                    self.currentUser = user
                }
            }
        }
    }

    private func startContinuousHeartRateMonitoring() {
        isMonitoringHeartRate = true
        heartRateDetectionStatus = "監視開始中"
        startWorkoutSession()
        startHeartRateTimeoutMonitoring()
    }

    private func stopContinuousHeartRateMonitoring() {
        workoutSession?.end()
        workoutSession = nil
        heartRateTimeoutTimer?.invalidate()
        heartRateTimeoutTimer = nil
        lastHeartRateUpdateTime = nil

        DispatchQueue.main.async {
            self.isMonitoringHeartRate = false
            self.currentHeartRate = 0
            self.heartRateDetectionStatus = "監視停止"
        }
    }

    private func startHeartRateTimeoutMonitoring() {
        heartRateTimeoutTimer?.invalidate()
        heartRateTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) {
            [weak self] _ in
            self?.checkHeartRateTimeout()
        }
    }

    private func checkHeartRateTimeout() {
        guard let lastUpdate = lastHeartRateUpdateTime else {
            DispatchQueue.main.async {
                self.heartRateDetectionStatus = "心拍数検知待機中"
            }
            return
        }

        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)

        if timeSinceLastUpdate > heartRateTimeout {
            DispatchQueue.main.async {
                self.currentHeartRate = 0
                self.heartRateDetectionStatus = "心拍数未検知"
            }

            sendHeartRateClearToiPhone()
        } else {
            DispatchQueue.main.async {
                self.heartRateDetectionStatus = "心拍数正常検知中"
            }
        }
    }

    private func startWorkoutSession() {

        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.isStarting = false
                self.heartRateDetectionStatus = "HealthStoreが利用できません"
            }
            return
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(
                healthStore: healthStore, configuration: configuration)

            let builder = workoutSession?.associatedWorkoutBuilder()

            let dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore, workoutConfiguration: configuration)
            builder?.dataSource = dataSource

            workoutSession?.delegate = self
            builder?.delegate = self

            workoutSession?.startActivity(with: Date())

            builder?.beginCollection(withStart: Date()) { [weak self] success, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if success {
                        self.isSending = true
                        self.heartRateDetectionStatus = "ワークアウト開始済み"
                    } else {
                        self.heartRateDetectionStatus = "ワークアウト開始失敗"
                    }
                    self.isStarting = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isStarting = false
                self.heartRateDetectionStatus = "ワークアウト作成エラー"
            }
        }
    }

    private func updateHeartRate(_ bpm: Int) {
        let now = Date()
        lastHeartRateUpdateTime = now

        DispatchQueue.main.async {
            if bpm > 0 && bpm <= 220 {
                self.currentHeartRate = bpm
                self.heartbeatSubject.send()
                self.heartRateDetectionStatus = "心拍数正常検知中"
            } else {
                self.heartRateDetectionStatus = "異常値検知"
            }
        }
    }

    func startSending() {
        guard !isSending, !isStarting else {
            return
        }

        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.heartRateDetectionStatus = "HealthKit利用不可"
            }
            return
        }

        isStarting = true
        consecutiveSendSkips = 0

        // まず権限をもう一度確認
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let authStatus = healthStore.authorizationStatus(for: heartRateType)

        switch authStatus {
        case .notDetermined:
            requestHealthKitPermission()
            DispatchQueue.main.async {
                // self.isStarting = false
                self.heartRateDetectionStatus = "HealthKit権限が必要です"
            }
            return
        //        case .sharingDenied:
        //            DispatchQueue.main.async {
        //                // self.isStarting = false
        //                self.heartRateDetectionStatus = "HealthKit権限が拒否されています"
        //            }
        //            return
        //        case .sharingAuthorized:
        @unknown default:
            print("HealthKit authorization: unknown")
        }

        // ワークアウト権限も確認
        let workoutAuth = healthStore.authorizationStatus(for: HKObjectType.workoutType())

        startContinuousHeartRateMonitoring()

        let sendInterval: TimeInterval = 3.0
        sendingTimer = Timer.scheduledTimer(withTimeInterval: sendInterval, repeats: true) {
            [weak self] _ in
            guard let self = self, self.isSending else { return }

            if self.shouldSendHeartRate() {
                self.sendHeartRateToiPhone(heartRate: self.currentHeartRate)
                self.consecutiveSendSkips = 0
            } else {
                self.consecutiveSendSkips += 1

                if self.consecutiveSendSkips >= self.maxConsecutiveSendSkips {
                    self.stopSending()
                }
            }
        }
    }

    private func shouldSendHeartRate() -> Bool {
        guard currentHeartRate > 0 else {
            return false
        }

        guard let lastUpdate = lastHeartRateUpdateTime else {
            return false
        }

        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        if timeSinceLastUpdate > heartRateTimeout {
            return false
        }

        return true
    }

    func stopSending() {
        isStarting = false
        isSending = false
        sendingTimer?.invalidate()
        sendingTimer = nil
        stopContinuousHeartRateMonitoring()
    }

    private func sendHeartRateToiPhone(heartRate: Int) {
        guard let session = wcSession, let user = currentUser else {
            return
        }

        let heartRateData: [String: Any] = [
            "heartNum": heartRate,
            "timestamp": Date().timeIntervalSince1970 * 1000,
            "userId": user.id,
            "isValidReading": true,
        ]
        let message: [String: Any] = ["type": "heartRate", "data": heartRateData]

        sendDataWithRetry(message: message, heartRate: heartRate, userName: user.name)
    }

    private func sendDataWithRetry(message: [String: Any], heartRate: Int, userName: String) {
        guard let session = wcSession else { return }

        session.transferUserInfo(message)

        DispatchQueue.main.async {
            self.sentCount += 1
        }
    }

    private func sendFallbackData(message: [String: Any], heartRate: Int) {
        guard let session = wcSession else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            session.transferUserInfo(message)
        }
    }

    private func sendHeartRateClearToiPhone() {
        guard let session = wcSession, let user = currentUser else {
            return
        }

        let clearData: [String: Any] = [
            "heartNum": 0,
            "timestamp": Date().timeIntervalSince1970 * 1000,
            "userId": user.id,
            "isValidReading": false,
            "status": "disconnected",
        ]
        let message: [String: Any] = ["type": "heartRate", "data": clearData]

        session.transferUserInfo(message)
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
            }
        }
    }
}

// MARK: - WCSessionDelegate & HealthKit Delegates
extension WatchHeartRateManager: WCSessionDelegate, HKWorkoutSessionDelegate,
    HKLiveWorkoutBuilderDelegate
{

    func session(
        _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {

        DispatchQueue.main.async {
            self.isConnected = (activationState == .activated)
            //            if activationState == .activated {
            //                print("WCSession is now active and connected")
            //            }
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {

        DispatchQueue.main.async {
            self.receivedDataCount += 1
        }

        guard let type = userInfo["type"] as? String else {
            return
        }

        if type == "selectUser" {
            if let userData = userInfo["user"] as? [String: Any] {
                handleUserSelection(userData)
            }
        } else if type == "userInfo" {
            if let data = userInfo["data"] as? [String: Any] {
                handleUserInfoData(data)
            }
        }
    }

    private func handleUserSelection(_ userData: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userData)
            let user = try JSONDecoder().decode(HeartUser.self, from: jsonData)
            DispatchQueue.main.async {
                self.currentUser = user
                self.saveUserToDefaults(user)
                if self.isSending {
                    self.stopSending()
                    self.startSending()
                }
            }
        } catch {
            DispatchQueue.main.async {
                print("error decoding user: \(error)")
            }
        }
    }

    private func handleUserInfoData(_ data: [String: Any]) {

        guard let userId = data["userId"] as? String,
            let userName = data["userName"] as? String
        else {
            return
        }

        let user = HeartUser(
            id: userId,
            name: userName
        )

        DispatchQueue.main.async {

            self.currentUser = user

            self.saveUserToDefaults(user)

            if self.isSending {
                self.stopSending()
                self.startSending()
            }
        }
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState, date: Date
    ) {

        DispatchQueue.main.async {
            switch toState {
            case .running:
                self.heartRateDetectionStatus = "ワークアウト実行中"
            case .paused:
                self.heartRateDetectionStatus = "ワークアウト一時停止"
            case .ended:
                self.heartRateDetectionStatus = "ワークアウト終了"
            case .notStarted:
                self.heartRateDetectionStatus = "ワークアウト未開始"
            case .prepared:
                self.heartRateDetectionStatus = "ワークアウト準備完了"
            case .stopped:
                self.heartRateDetectionStatus = "ワークアウト停止"
            @unknown default:
                print("Unknown workout session state")
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.heartRateDetectionStatus = "ワークアウトエラー: \(error.localizedDescription)"
        }
    }

    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        for type in collectedTypes {
            if type == HKObjectType.quantityType(forIdentifier: .heartRate) {
                guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
                    let statistics = workoutBuilder.statistics(for: heartRateType)
                else {
                    return
                }

                if let mostRecentQuantity = statistics.mostRecentQuantity() {
                    let heartRateUnit = HKUnit(from: "count/min")
                    let heartRate = Int(mostRecentQuantity.doubleValue(for: heartRateUnit))
                    updateHeartRate(heartRate)
                }
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

import Combine
import FirebaseAuth
import FirebaseDatabase
import Foundation
import UIKit
import WatchConnectivity

// iPhone側でApple Watchとの通信を管理するクラス
class ConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    // UIに公開するプロパティ
    @Published var heartRate: Int = 0
    @Published var isReachable: Bool = false
    @Published var lastSavedTimestamp: Date?
    @Published var saveCount: Int = 0
    @Published var isAppActive: Bool = true

    // Viewに鼓動を通知するための仕組み
    let heartbeatSubject = PassthroughSubject<Void, Never>()

    // ★ 最後に保存したBPM値を記録（BPM変化検出用）
    private var lastSavedBpm: Int?

    // ★ 最後に通知を送信した時刻（1時間レート制限用）
    private var lastNotificationSentTime: Date? {
        didSet {
            // UserDefaultsに永続化（アプリ再起動時の復元用）
            if let time = lastNotificationSentTime {
                UserDefaults.standard.set(
                    time.timeIntervalSince1970, forKey: "lastNotificationSentTime")
            } else {
                UserDefaults.standard.removeObject(forKey: "lastNotificationSentTime")
            }
        }
    }
    private let notificationCooldownInterval: TimeInterval = 3600.0  // 1時間

    private var session: WCSession
    private var database: DatabaseReference
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var receivedDataQueue: [(userInfo: [String: Any], timestamp: Date)] = []
    private var processingTimer: Timer?

    // ★ タイムアウト管理を追加
    private var heartRateTimeoutTimer: Timer?
    private let heartRateTimeout: TimeInterval = 10.0  // 10秒でタイムアウト
    private var lastHeartRateReceived: Date?

    init(session: WCSession = .default) {
        self.session = session
        self.database = Database.database().reference()
        super.init()

        // UserDefaultsから最後の通知時刻を復元
        if let timestamp = UserDefaults.standard.object(forKey: "lastNotificationSentTime")
            as? TimeInterval
        {
            self.lastNotificationSentTime = Date(timeIntervalSince1970: timestamp)
            print("📅 最後の通知時刻を復元: \(Date(timeIntervalSince1970: timestamp))")
        }

        self.session.delegate = self
        session.activate()

        // アプリのライフサイクル監視を開始
        setupAppLifecycleObservers()

        // バックグラウンドでのデータ処理タイマーを開始
        startBackgroundProcessingTimer()

        // 心拍数タイムアウト監視を開始
        startHeartRateTimeoutMonitoring()

        // 初期化完了を待ってユーザー情報を送信
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendCurrentUserToWatch()
        }
    }

    // MARK: - Heart Rate Timeout Management

    private func startHeartRateTimeoutMonitoring() {
        heartRateTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] _ in
            self?.checkHeartRateTimeout()
        }
    }

    private func checkHeartRateTimeout() {
        guard let lastReceived = lastHeartRateReceived,
            heartRate > 0
        else { return }

        let timeSinceLastData = Date().timeIntervalSince(lastReceived)

        if timeSinceLastData >= heartRateTimeout {
            print("心拍数タイムアウト")
            DispatchQueue.main.async {
                self.resetHeartRate()
            }
        }
    }

    private func resetHeartRate() {
        heartRate = 0
        lastHeartRateReceived = nil
        // ★ BPM記録もリセット（次回の変化を確実に検出するため）
        lastSavedBpm = nil
        print("💫 心拍数リセット完了")
    }

    private func updateHeartRateReceived() {
        lastHeartRateReceived = Date()
    }

    // MARK: - アプリライフサイクル監視

    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        DispatchQueue.main.async {
            self.isAppActive = true
        }
        endBackgroundTask()
        processQueuedData()
    }

    @objc private func appWillResignActive() {
        DispatchQueue.main.async {
            self.isAppActive = false
        }
    }

    @objc private func appDidEnterBackground() {
        startBackgroundTask()
    }

    @objc private func appWillEnterForeground() {
        endBackgroundTask()
        processQueuedData()
    }

    // MARK: - バックグラウンドタスク管理

    private func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "HeartRateSync") {
            [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    // MARK: - バックグラウンド処理タイマー

    private func startBackgroundProcessingTimer() {
        processingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {
            [weak self] _ in
            self?.processQueuedData()
        }
    }

    private func processQueuedData() {
        guard !receivedDataQueue.isEmpty else { return }

        // キューからすべてのデータを取得
        let dataToProcess = receivedDataQueue
        receivedDataQueue.removeAll()

        // 最新のデータのみ処理（同じユーザーIDの場合）
        var latestDataByUser: [String: (userInfo: [String: Any], timestamp: Date)] = [:]

        for item in dataToProcess {
            if let data = item.userInfo["data"] as? [String: Any],
                let userId = data["userId"] as? String
            {
                // より新しいデータがあるかチェック
                if let existing = latestDataByUser[userId] {
                    if item.timestamp > existing.timestamp {
                        latestDataByUser[userId] = item
                    }
                } else {
                    latestDataByUser[userId] = item
                }
            }
        }

        // 最新データを処理
        for (_, item) in latestDataByUser {
            processHeartRateData(item.userInfo)
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isReachable = (activationState == .activated)

            // ★ 接続が切れた場合は心拍数をリセット
            if activationState != .activated {
                self.resetHeartRate()
            } else {
                // アクティブになったらユーザー情報を送信
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.sendCurrentUserToWatch()
                }
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = false
            // ★ 接続が切れた場合は心拍数をリセット
            self.resetHeartRate()
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            // ★ 接続が切れた場合は心拍数をリセット
            self.resetHeartRate()
        }
        // 再度アクティベートを試みる
        self.session.activate()
    }

    // ★ セッション到達可能性変更時
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable

            // ★ 到達不可能になったら心拍数をリセット
            if !session.isReachable {
                self.resetHeartRate()
            }
        }
    }

    // Watchからデータを受信したときに呼ばれるメソッド
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        let timestamp = Date()

        // アプリがアクティブな場合は即座に処理、そうでなければキューに追加
        if isAppActive {
            processHeartRateData(userInfo)
        } else {
            receivedDataQueue.append((userInfo: userInfo, timestamp: timestamp))

            // バックグラウンドタスクを開始（まだ開始されていない場合）
            if backgroundTaskID == .invalid {
                startBackgroundTask()
            }
        }
    }

    // リアルタイムメッセージ受信も追加
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // 停止メッセージの処理
        if let type = message["type"] as? String {
            switch type {
            case "heartRateStop":
                print("⏹Watch側から停止通知受信")
                DispatchQueue.main.async {
                    self.resetHeartRate()
                }
                return
            case "heartRateStart":
                print("Watch側から開始通知受信")
                return
            default:
                break
            }
        }

        // 通常の心拍数データ処理
        processHeartRateData(message)
    }

    private func processHeartRateData(_ userInfo: [String: Any]) {
        // "heartRate"タイプのデータか確認
        guard let type = userInfo["type"] as? String,
            type == "heartRate",
            let data = userInfo["data"] as? [String: Any],
            let bpm = data["heartNum"] as? Int,
            data["userId"] is String
        else {
            return
        }

        // ★ クリア信号の確認を強化
        if let status = data["status"] as? String, status == "disconnected" || status == "stopped" {
            DispatchQueue.main.async {
                self.resetHeartRate()
            }
            return
        }

        // bpm = 0 の場合も停止として扱う
        if bpm <= 0 {
            DispatchQueue.main.async {
                self.resetHeartRate()
            }
            return
        }

        // 心拍数の妥当性チェック
        guard isValidHeartRate(bpm) else {
            return
        }

        // 有効な読み取り値かチェック（Watch側から送信される場合）
        if let isValidReading = data["isValidReading"] as? Bool, !isValidReading {
            return
        }

        // ★ データ受信時刻を更新
        updateHeartRateReceived()

        // UIをメインスレッドで更新
        DispatchQueue.main.async {
            self.heartRate = bpm

            // Viewに「鼓動の合図」を送る
            if bpm > 0 {
                self.heartbeatSubject.send()
            }
        }

        // Firebase Realtime Databaseに保存
        saveHeartRateToFirebase(data: data)
    }

    // 心拍数の妥当性をチェック
    private func isValidHeartRate(_ bpm: Int) -> Bool {
        // 0以下または異常に高い値（220以上）は無効とする
        return bpm > 0 && bpm <= 220
    }

    // MARK: - Firebase Realtime Database

    private func saveHeartRateToFirebase(data: [String: Any]) {
        guard let heartNum = data["heartNum"] as? Int,
            let timestamp = data["timestamp"] as? Double,
            let userId = data["userId"] as? String
        else {
            return
        }

        // ★ BPMが変化していない場合はFirebaseへの送信をスキップ
        if let lastBpm = lastSavedBpm, lastBpm == heartNum {
            print("💡 BPM変化なし（\(heartNum) bpm）- Firebase送信スキップ")
            return
        }

        let now = Date()

        // Firebase用のデータ構造（リアルタイム表示用）
        let heartRateData: [String: Any] = [
            "bpm": heartNum,
            "timestamp": timestamp,  // Watch側からのタイムスタンプ（ミリ秒単位）
        ]

        // データベースパス: /live_heartbeats/{userId}（リアルタイム表示用）
        let heartRateRef = database.child("live_heartbeats").child(userId)

        heartRateRef.setValue(heartRateData) { [weak self] error, _ in
            DispatchQueue.main.async {
                if error != nil {
                    print("❌ Firebase更新エラー")
                } else {
                    print("✅ Firebase送信成功: \(heartNum) bpm")
                    self?.lastSavedTimestamp = now
                    self?.saveCount += 1
                    // ★ 送信成功時に最後のBPM値を記録
                    self?.lastSavedBpm = heartNum
                }
            }
        }

        // ★ 通知送信チェック（1時間経過 & BPM変化）
        checkAndTriggerNotification(userId: userId, bpm: heartNum, timestamp: timestamp)
    }

    /// 1時間経過チェック & 通知トリガー
    private func checkAndTriggerNotification(userId: String, bpm: Int, timestamp: Double) {
        let now = Date()

        // 1時間経過チェック
        if let lastNotificationTime = lastNotificationSentTime {
            let timeSinceLastNotification = now.timeIntervalSince(lastNotificationTime)

            if timeSinceLastNotification < notificationCooldownInterval {
                let remainingTime = Int(notificationCooldownInterval - timeSinceLastNotification)
                print("⏳ 通知クールダウン中: あと\(remainingTime)秒")
                return
            }
        }

        // ★ 1時間経過している（または初回）→ 通知トリガーパスに最小限のデータを書き込み
        // Functions側でlive_heartbeatsから実際のBPMを取得する
        let notificationTriggerData: [String: Any] = [
            "t": now.timeIntervalSince1970 * 1000  // トリガー時刻のみ
        ]

        let triggerRef = database.child("notification_triggers").child(userId)

        triggerRef.setValue(notificationTriggerData) { [weak self] error, _ in
            if error != nil {
                print("❌ 通知トリガー送信エラー")
            } else {
                print("🔔 通知トリガー送信成功")
                // ★ 最後の通知時刻を記録（UserDefaultsに自動保存される）
                self?.lastNotificationSentTime = now
            }
        }
    }

    private func sendCurrentUserToWatch() {
        // FirebaseAuthから現在のユーザーを取得
        guard let currentUser = Auth.auth().currentUser else {
            return
        }

        let userId = currentUser.uid
        let userName = currentUser.displayName ?? "Unknown User"

        let userInfo: [String: Any] = [
            "type": "userInfo",
            "data": [
                "userId": userId,
                "userName": userName,
            ],
        ]

        session.transferUserInfo(userInfo)

        // リーチャブルな場合は即座にも送信
        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil) { _ in
            }
        }
    }

    // WCSessionがアクティブになったときに呼び出す
    func sendUserToWatchIfNeeded() {
        guard session.activationState == .activated else {
            return
        }
        sendCurrentUserToWatch()
    }

    deinit {
        // タイマーをクリーンアップ
        processingTimer?.invalidate()
        heartRateTimeoutTimer?.invalidate()

        // オブザーバーを削除
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - データモデル
struct HeartRateRecord: Identifiable, Codable {
    let id: String
    let heartRate: Int
    let timestamp: Date
    let userId: String

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp)
    }
}

import Foundation
import WatchConnectivity
import Combine
import FirebaseDatabase
import UIKit

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
    
    private var session: WCSession
    private var database: DatabaseReference
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var receivedDataQueue: [(userInfo: [String: Any], timestamp: Date)] = []
    private var processingTimer: Timer?
    
    init(session: WCSession = .default) {
        self.session = session
        self.database = Database.database().reference()
        super.init()
        self.session.delegate = self
        session.activate()
        
        // アプリのライフサイクル監視を開始
        setupAppLifecycleObservers()
        
        // バックグラウンドでのデータ処理タイマーを開始
        startBackgroundProcessingTimer()
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
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "HeartRateSync") { [weak self] in
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
        processingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
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
               let userId = data["userId"] as? String {
                
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
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = (activationState == .activated)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // 再度アクティベートを試みる
        self.session.activate()
    }
    
    // Watchからデータを受信したときに呼ばれるメソッド
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
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
    
    private func processHeartRateData(_ userInfo: [String: Any]) {
        
        // "heartRate"タイプのデータか確認
        guard let type = userInfo["type"] as? String,
              type == "heartRate",
              let data = userInfo["data"] as? [String: Any],
              let bpm = data["heartNum"] as? Int,
              let userId = data["userId"] as? String else {
            return
        }
        
        // クリア信号の確認
        if let status = data["status"] as? String, status == "disconnected" || bpm == 0 {
            
            // UIをクリア
            DispatchQueue.main.async {
                self.heartRate = 0
            }
            
            // // Firebaseもクリア
            // clearHeartRateData(for: userId)
            return
        }
        
        // 心拍数の妥当性チェック
        guard isValidHeartRate(bpm) else {
            print("無効な心拍数を受信")
            return
        }
        
        // 有効な読み取り値かチェック（Watch側から送信される場合）
        if let isValidReading = data["isValidReading"] as? Bool, !isValidReading {
            return
        }
        
        print("有効な心拍数を受信")
        
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
              let userId = data["userId"] as? String else {
            return
        }
        
        // 現在の日時をISO8601形式で取得
        let now = Date()
        let formatter = ISO8601DateFormatter()
        let isoTimestamp = formatter.string(from: now)
        
        // Firebase用のデータ構造
        let heartRateData: [String: Any] = [
          // タイムスタンプはどれがいい...
            "heartNum": heartNum,
            "timestamp": timestamp, // Watch側からのタイムスタンプ
            "serverTimestamp": ServerValue.timestamp(), // サーバー側のタイムスタンプ
            "isoTimestamp": isoTimestamp, // ISO8601形式のタイムスタンプ
            "userId": userId,
            "lastUpdated": ServerValue.timestamp() // 最終更新時刻
        ]
        
        // データベースパス: /{userId}（常に同じ場所を更新）
        let heartRateRef = database.child(userId)
        
        print("Firebase更新開始")
        
        heartRateRef.setValue(heartRateData) { [weak self] error, _ in
            DispatchQueue.main.async {
                if let error = error {
                    print("Firebase更新エラー")
                } else {
                    self?.lastSavedTimestamp = now
                    self?.saveCount += 1
                }
            }
        }
    }
    
    // 心拍数データをクリア（Watch外した時やアプリ終了時）
    // func clearHeartRateData(for userId: String) {
    //     let heartRateRef = database.child("heartRates").child(userId).child("current")
        
    //     let clearData: [String: Any] = [
    //         "heartNum": 0,
    //         "status": "disconnected",
    //         "lastUpdated": ServerValue.timestamp(),
    //         "userId": userId,
    //     ]
        
    //     heartRateRef.setValue(clearData) { error, _ in
    //         if let error = error {
    //             print("データクリアエラー")
    //         } else {
    //             print("データクリア成功")
    //         }
    //     }
    // }
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

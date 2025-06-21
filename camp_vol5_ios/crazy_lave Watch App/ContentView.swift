import SwiftUI
import HealthKit
import WatchConnectivity
import Combine

struct ContentView: View {
    @StateObject private var watchManager = WatchHeartRateManager()
    
    // アニメーションの状態を管理する変数
    @State private var isBeating: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                // MARK: - 中央の心拍数表示エリア
                ZStack {
                    // 通常時のハート（小さい）
                    Image("heart")
                        .renderingMode(.original)
                        .font(.system(size: 120))
                        .scaleEffect(isBeating ? 1.25 : 1.0)
                        .opacity(isBeating ? 0.0 : 1.0)
                    
                    // 鼓動時のハート（大きい・明るい）
                    Image("heart")
                        .renderingMode(.original)
                        .font(.system(size: 120))
                        .scaleEffect(isBeating ? 1.25 : 1.0)
                        .opacity(isBeating ? 1.0 : 0.0)
                        .shadow(color: .red, radius: 10, x: 0, y: 0) // 発光しているように見せる影
                    
                    // 中央の心拍数
                    if watchManager.currentHeartRate > 0 {
                        Text("\(watchManager.currentHeartRate)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    } else {
                        Text("－")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isBeating)
                .frame(height: 100)
                .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: isBeating) { _, isBeatingNow in
                    return isBeatingNow
                }
                
                // MARK: - デバッグ情報表示
                if watchManager.currentUser == nil {
                    VStack(spacing: 2) {
                        Text("受信待機中...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("データ受信: \(watchManager.receivedDataCount)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - 下部のコントロールエリア
                if watchManager.currentUser != nil {
                    Button(action: {
                        if watchManager.isSending {
                            watchManager.stopSending()
                        } else {
                            watchManager.startSending()
                        }
                    }) {
                        ZStack {
                            HStack {
                                Image(systemName: "stop.fill")
                                    .font(.caption)
                                Text("停止")
                                    .font(.caption)
                            }
                            .opacity(watchManager.isSending && !watchManager.isStarting ? 1 : 0)
                            
                            ProgressView()
                                .scaleEffect(0.8)
                                .opacity(watchManager.isStarting ? 1 : 0)
                            
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.caption)
                                Text("開始")
                                    .font(.caption)
                            }
                            .opacity(!watchManager.isSending && !watchManager.isStarting ? 1 : 0)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            watchManager.isStarting ? Color.gray : (watchManager.isSending ? Color.red : Color.green)
                        )
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    .disabled(!watchManager.isConnected || watchManager.isStarting)
                    .padding(.horizontal, 8)
                } else {
                    // ユーザー情報がない場合のデバッグボタン
                    Button("再接続") {
                        watchManager.reconnect()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                }
                
                // 最下部のスペース
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .onAppear {
            watchManager.setup()
        }
        .onDisappear {
            watchManager.cleanup()
        }
        .onReceive(watchManager.heartbeatSubject) { _ in
            isBeating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isBeating = false
            }
        }
    }
    
    // 心拍数検知状況に応じた色を返す
    private var heartRateStatusColor: Color {
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

// MARK: - Data Models
struct HeartUser: Codable, Equatable {
    let id: String
    let name: String
    
    // iPhone側のUserモデルとの互換性を保つ
    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Watch Heart Rate Manager
class WatchHeartRateManager: NSObject, ObservableObject {
    @Published var currentHeartRate: Int = 0 // 最新の心拍数
    @Published var isSending: Bool = false // 心拍数送信中かどうか
    @Published var sentCount: Int = 0 // 送信した心拍数のカウント
    @Published var isConnected: Bool = false // Apple Watchとの接続状態
    @Published var currentUser: HeartUser? // 現在のユーザー情報
    @Published var isMonitoringHeartRate: Bool = false // 心拍数監視中かどうか
    @Published var isStarting: Bool = false // 心拍数送信開始中かどうか
    @Published var receivedDataCount: Int = 0 // デバッグ用
    @Published var heartRateDetectionStatus: String = "待機中" // 心拍数検知状況
    
    let heartbeatSubject = PassthroughSubject<Void, Never>()
    private var healthStore = HKHealthStore()
    private var wcSession: WCSession?
    private var sendingTimer: Timer?
    private var workoutSession: HKWorkoutSession?
    private var lastHeartRateUpdateTime: Date?
    private var heartRateTimeoutTimer: Timer?
    private let heartRateTimeout: TimeInterval = 15.0 // 15秒間心拍数が更新されない場合はタイムアウト
    
    // 自動停止
    private var consecutiveSendSkips: Int = 0
    private let maxConsecutiveSendSkips: Int = 5 // 5回連続でスキップしたら停止
    
    override init() {
        super.init()
        // 保存されたユーザー情報を復元
        restoreUserFromDefaults()
    }
    
    func setup() {
        setupWatchConnectivity()
        requestHealthKitPermission()
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
        } else {
        }
    }
    
    private func requestHealthKitPermission() {
        let typesToRead: Set = [HKObjectType.quantityType(forIdentifier: .heartRate)!, HKObjectType.workoutType()]
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit error: \(error)")
            }
        }
    }
    
    // ユーザー情報をUserDefaultsに保存
    private func saveUserToDefaults(_ user: HeartUser) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentWatchUser")
        }
    }
    
    // ユーザー情報をUserDefaultsから復元
    private func restoreUserFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: "currentWatchUser"),
           let user = try? JSONDecoder().decode(HeartUser.self, from: data) {
            DispatchQueue.main.async {
                self.currentUser = user
            }
        }
    }
    
    // 心拍数の監視を開始
    private func startContinuousHeartRateMonitoring() {
        isMonitoringHeartRate = true
        heartRateDetectionStatus = "監視開始中"
        startWorkoutSession()
        startHeartRateTimeoutMonitoring()
    }
    
    // 心拍数の監視を停止
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
    
    // 心拍数タイムアウト監視を開始
    private func startHeartRateTimeoutMonitoring() {
        heartRateTimeoutTimer?.invalidate()
        heartRateTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkHeartRateTimeout()
        }
    }
    
    // 心拍数のタイムアウトチェック
    private func checkHeartRateTimeout() {
        guard let lastUpdate = lastHeartRateUpdateTime else {
            // まだ一度も心拍数を受信していない
            DispatchQueue.main.async {
                self.heartRateDetectionStatus = "心拍数検知待機中"
            }
            return
        }
        
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        
        if timeSinceLastUpdate > heartRateTimeout {
            // タイムアウト：心拍数が検知されていない
            print("心拍数タイムアウト")
            DispatchQueue.main.async {
                self.currentHeartRate = 0
                self.heartRateDetectionStatus = "心拍数未検知"
            }
            
            // iPhone側にクリア信号を送信
            sendHeartRateClearToiPhone()
        } else {
            DispatchQueue.main.async {
                self.heartRateDetectionStatus = "心拍数正常検知中"
            }
        }
    }
    
    // ワークアウトセッションを開始
    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = workoutSession?.associatedWorkoutBuilder()
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
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
                        print("ワークアウトセッション開始失敗")
                    }
                    self.isStarting = false
                }
            }
        } catch {
            print("ワークアウトセッション作成エラー")
            DispatchQueue.main.async {
                self.isStarting = false
                self.heartRateDetectionStatus = "ワークアウト作成エラー"
            }
        }
    }
    
    // 心拍数更新処理
    private func updateHeartRate(_ bpm: Int) {
        let now = Date()
        lastHeartRateUpdateTime = now
        
        DispatchQueue.main.async {
            // 有効な心拍数のみ更新（0以下や異常に高い値は除外）
            if bpm > 0 && bpm <= 220 {
                self.currentHeartRate = bpm
                self.heartbeatSubject.send()
                self.heartRateDetectionStatus = "心拍数正常検知中"
            } else {
                self.heartRateDetectionStatus = "異常値検知"
            }
        }
    }
    
    // 心拍数送信を開始
    func startSending() {
        guard !isSending, !isStarting else { return }
        isStarting = true
        // 送信開始時にスキップカウンターをリセット
        consecutiveSendSkips = 0
        
        startContinuousHeartRateMonitoring()
        
        let sendInterval: TimeInterval = 3.0
        sendingTimer = Timer.scheduledTimer(withTimeInterval: sendInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isSending else { return }
            
            // 心拍数が有効で、最近更新されている場合のみ送信
            if self.shouldSendHeartRate() {
                self.sendHeartRateToiPhone(heartRate: self.currentHeartRate)
                // カウンターをリセット
                self.consecutiveSendSkips = 0
            } else {
                self.consecutiveSendSkips += 1
                print("送信スキップ")
                
                if self.consecutiveSendSkips >= self.maxConsecutiveSendSkips {
                    self.stopSending()
                }
            }
        }
    }
    
    // 心拍数を送信すべきかどうかの判定
    private func shouldSendHeartRate() -> Bool {
        // 心拍数が0以下の場合は送信しない
        guard currentHeartRate > 0 else {
            return false
        }
        
        // 最後の心拍数更新から一定時間経過している場合は送信しない
        guard let lastUpdate = lastHeartRateUpdateTime else {
            return false
        }
        
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        if timeSinceLastUpdate > heartRateTimeout {
            return false
        }
        
        return true
    }
    
    // 心拍数送信を停止
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
            "isValidReading": true // 有効な読み取り値であることを明示
        ]
        let message: [String: Any] = ["type": "heartRate", "data": heartRateData]
        
        // 複数の送信方法を試行
        sendDataWithRetry(message: message, heartRate: heartRate, userName: user.name)
    }
    
    // 複数の方法でデータ送信を試行
    private func sendDataWithRetry(message: [String: Any], heartRate: Int, userName: String) {
        guard let session = wcSession else { return }
        
        session.transferUserInfo(message)
        
        DispatchQueue.main.async {
            self.sentCount += 1
        }
    }
    
    // フォールバック送信
    private func sendFallbackData(message: [String: Any], heartRate: Int) {
        guard let session = wcSession else { return }
        
        // より確実な送信のため、少し遅延してから再送信
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            session.transferUserInfo(message)
            print("⌚ 🔄 フォールバック送信: \(heartRate) BPM")
        }
    }
    
    // 心拍数クリア信号をiPhoneに送信
    private func sendHeartRateClearToiPhone() {
        guard let session = wcSession, let user = currentUser else {
            return
        }
        
        let clearData: [String: Any] = [
            "heartNum": 0,
            "timestamp": Date().timeIntervalSince1970 * 1000,
            "userId": user.id,
            "isValidReading": false,
            "status": "disconnected" // 切断状態を明示
        ]
        let message: [String: Any] = ["type": "heartRate", "data": clearData]
        
        // クリア信号も複数方法で送信
        session.transferUserInfo(message)
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                print("⌚クリア信号sendMessage失敗")
            }
        }
    }
}

// MARK: - WCSessionDelegate & HealthKit Delegates
extension WatchHeartRateManager: WCSessionDelegate, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation error")
        }
        DispatchQueue.main.async {
            self.isConnected = (activationState == .activated)
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        
        DispatchQueue.main.async {
            self.receivedDataCount += 1
        }
        
        // データタイプを確認
        guard let type = userInfo["type"] as? String else {
            return
        }
        
        if type == "selectUser" {
            // 既存の形式
            if let userData = userInfo["user"] as? [String: Any] {
                handleUserSelection(userData)
            }
        } else if type == "userInfo" {
            if let data = userInfo["data"] as? [String: Any] {
                handleUserInfoData(data)
            }
        } else {
            print("未対応のデータタイプ")
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
            print("ユーザーデータの解析に失敗")
        }
    }
    
    private func handleUserInfoData(_ data: [String: Any]) {
        guard let userId = data["userId"] as? String,
              let userName = data["userName"] as? String else {
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
    
    // HKWorkoutSessionDelegate
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("ワークアウトセッション状態変更")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("ワークアウトセッションエラー:")
    }
    
    // HKLiveWorkoutBuilderDelegate
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let statistics = workoutBuilder.statistics(for: heartRateType),
              let mostRecentQuantity = statistics.mostRecentQuantity() else { return }
        let heartRateUnit = HKUnit(from: "count/min")
        let heartRate = Int(mostRecentQuantity.doubleValue(for: heartRateUnit))
        updateHeartRate(heartRate)
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

//import SwiftUI
//
///// UIの表示に特化したView
//struct ContentView: View {
//    @StateObject private var viewModel = WatchViewModel()
//    @State private var isBeating = false
//
//    var body: some View {
//        VStack(spacing: 8) {
//            Text(viewModel.currentUser?.name ?? "iPhoneでユーザー選択")
//                .font(viewModel.currentUser != nil ? .headline : .caption)
//                .foregroundColor(viewModel.currentUser != nil ? .primary : .secondary)
//
//            Spacer()
//
//            ZStack {
//                Image(systemName: "heart.fill").resizable().aspectRatio(contentMode: .fit)
//                    .frame(width: 120).foregroundStyle(Color.red.opacity(0.2))
//                
//                Image(systemName: "heart.fill").resizable().aspectRatio(contentMode: .fit)
//                    .frame(width: 120).scaleEffect(isBeating ? 1.1 : 1.0)
//                    .foregroundStyle(.red).opacity(isBeating ? 1.0 : 0.5)
//                    .shadow(color: .red, radius: isBeating ? 15 : 0)
//
//                if viewModel.currentHeartRate > 0 {
//                    Text("\(viewModel.currentHeartRate)").font(.system(size: 42, weight: .bold, design: .rounded))
//                        .foregroundStyle(.white).shadow(radius: 2)
//                } else if viewModel.isStarting || viewModel.isMonitoring {
//                    ProgressView()
//                } else {
//                    Text("－").font(.system(size: 42, weight: .bold))
//                }
//            }.animation(.spring(response: 0.15, dampingFraction: 0.4), value: isBeating)
//            
//            Spacer()
//
//            Text(viewModel.statusMessage).font(.caption2).foregroundColor(.secondary)
//
//            Button(action: {
//                if viewModel.isMonitoring { viewModel.stopMonitoring() } else { viewModel.startMonitoring() }
//            }) {
//                ZStack {
//                    ProgressView().opacity(viewModel.isStarting ? 1 : 0)
//                    HStack {
//                        Image(systemName: viewModel.isMonitoring ? "stop.fill" : "play.fill")
//                        Text(viewModel.isMonitoring ? "停止" : "開始")
//                    }.opacity(viewModel.isStarting ? 0 : 1)
//                }.frame(maxWidth: .infinity).padding(.vertical, 8)
//            }
//            .tint(viewModel.isMonitoring ? .red : (viewModel.isStarting ? .gray : .green))
//            .buttonStyle(.borderedProminent)
//            .disabled(viewModel.currentUser == nil || viewModel.isStarting)
//        }
//        .padding()
//        .onReceive(viewModel.$currentHeartRate) { _ in
//            isBeating.toggle()
//        }
//    }
//}

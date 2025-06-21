import SwiftUI
import HealthKit
import WatchConnectivity
import Combine

struct ContentView: View {
    @StateObject private var watchManager = WatchHeartRateManager()
    
    // アニメーションの状態を管理する変数
    @State private var isBeating: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // MARK: - 中央の心拍数表示エリア
            ZStack {
                // 通常時のハート（小さい）
                Image("heart")
                    .renderingMode(.original)
                    .font(.system(size: 150))
                    .scaleEffect(isBeating ? 1.25 : 1.0) // 鼓動時に少し大きくなる
                    .opacity(isBeating ? 0.0 : 1.0)   // 鼓動時に透明になる
                
                // 鼓動時のハート（大きい・明るい）
                Image("heart")
                    .renderingMode(.original)
                    .font(.system(size: 150))
                    .scaleEffect(isBeating ? 1.25 : 1.0)
                    .opacity(isBeating ? 1.0 : 0.0)
                    .shadow(color: .red, radius: 10, x: 0, y: 0) // 発光しているように見せる影
                
                // 中央の心拍数
                if watchManager.currentHeartRate > 0 {
                    Text("\(watchManager.currentHeartRate)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                } else {
                    Text("－")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isBeating) // isBeatingの変化をアニメーションさせる
            .frame(height: 120)
            .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: isBeating) { _, isBeatingNow in
                // 鼓動した瞬間だけ振動させる
                return isBeatingNow
            }
            
            Spacer()
            
            // MARK: - 下部のコントロールエリア
            VStack(spacing: 6) {
                // ステータス表示
                HStack {
                    Label("\(watchManager.sentCount)", systemImage: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                    Spacer()
                    Label(watchManager.isConnected ? "接続OK" : "未接続", systemImage: "antenna.radiowaves.left.and.right")
                        .foregroundColor(watchManager.isConnected ? .green : .gray)
                }
                .font(.caption)
                .padding(.horizontal, 12)
                
                // 操作ボタン
                if watchManager.currentUser != nil {
                    Button(action: {
                        if watchManager.isSending {
                            watchManager.stopSending()
                        } else {
                            watchManager.startSending()
                        }
                    }) {
                        HStack {
                            Image(systemName: watchManager.isSending ? "stop.fill" : "play.fill")
                            Text(watchManager.isSending ? "停止" : "開始")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(watchManager.isSending ? Color.red : Color.green)
                        .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!watchManager.isConnected)
                } else {
                    Text("iPhoneでユーザーを選択")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .onAppear {
            watchManager.setup()
        }
        .onDisappear {
            watchManager.cleanup()
        }
        .onReceive(watchManager.heartbeatSubject) { _ in
            // 鼓動の合図を受け取ったらアニメーションを発火
            isBeating = true
            // 0.2秒後にアニメーションを元の状態に戻す
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isBeating = false
            }
        }
    }
}

// MARK: - Data Models
struct HeartUser: Codable {
    let id: String
    let name: String
    let description: String
    let tag: String
    let isPublic: Bool
    let password: String
    let sendInterval: TimeInterval
    let isActive: Bool
}

// MARK: - Watch Heart Rate Manager
class WatchHeartRateManager: NSObject, ObservableObject {
    // UI用プロパティ
    @Published var currentHeartRate: Int = 0
    @Published var isSending: Bool = false
    @Published var sentCount: Int = 0
    @Published var isConnected: Bool = false
    @Published var currentUser: HeartUser?
    @Published var isMonitoringHeartRate: Bool = false
    
    // 内部用プロパティ
    private var healthStore = HKHealthStore()
    private var wcSession: WCSession?
    private var sendingTimer: Timer?
    private var workoutSession: HKWorkoutSession?
    // Content Vireへ鼓動したことを通知するためのSubject
    let heartbeatSubject = PassthroughSubject<Void, Never>()

    override init() {
        super.init()
    }
    
    func setup() {
        setupWatchConnectivity()
        requestHealthKitPermission()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        } else {
            print("Watch Connectivityはサポートされていません")
        }
    }
    
    func cleanup() {
        stopSending()
    }
    
    // MARK: - HealthKit
    private func requestHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKitは利用できません")
            return
        }
        
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if !success {
                print("HealthKitのアクセスが許可されませんでした: \(error?.localizedDescription ?? "Unknown error")")
            } else {
                print("HealthKitのアクセス許可完了")
            }
        }
    }
    
    private func startContinuousHeartRateMonitoring() {
        print("心拍数の継続監視を開始")
        DispatchQueue.main.async {
            self.isMonitoringHeartRate = true
        }
        startWorkoutSession()
    }
    
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
            builder?.beginCollection(withStart: Date()) { success, error in
                if success {
                    print("ワークアウトセッションを開始しました")
                } else {
                    print("ワークアウトセッションの開始に失敗: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        } catch {
            print("ワークアウトセッションの作成に失敗: \(error.localizedDescription)")
        }
    }
    
    private func stopContinuousHeartRateMonitoring() {
        print("心拍数の継続監視を停止")
        workoutSession?.end()
        workoutSession = nil
        DispatchQueue.main.async {
            self.isMonitoringHeartRate = false
            self.currentHeartRate = 0
        }
    }
    
    private func updateHeartRate(_ bpm: Int) {
        DispatchQueue.main.async {
            self.currentHeartRate = bpm
            // 有効な心拍数を検知したら、鼓動イベントを送信
            if bpm > 0 {
                self.heartbeatSubject.send()
            }
        }
    }
    
    // MARK: - Data Sending
    func startSending() {
        guard let user = currentUser, isConnected else { return }
        
        isSending = true
        startContinuousHeartRateMonitoring()
        
        // 即座に最初のデータを送信
        if currentHeartRate > 0 {
            sendHeartRateToiPhone(heartRate: currentHeartRate, user: user)
        }
        
        // 定期送信タイマーを開始
        sendingTimer = Timer.scheduledTimer(withTimeInterval: user.sendInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.currentHeartRate > 0, self.isSending else { return }
            self.sendHeartRateToiPhone(heartRate: self.currentHeartRate, user: user)
        }
    }
    
    func stopSending() {
        isSending = false
        sendingTimer?.invalidate()
        sendingTimer = nil
        stopContinuousHeartRateMonitoring()
    }
    
    private func sendHeartRateToiPhone(heartRate: Int, user: HeartUser) {
        guard let session = wcSession else { return }
        
        let heartRateData: [String: Any] = [
            "heartNum": heartRate,
            "timestamp": Date().timeIntervalSince1970 * 1000,
            "userId": user.id,
        ]
        let message: [String: Any] = [
            "type": "heartRate",
            "data": heartRateData
        ]
        
        // バックグラウンドで送信
        session.transferUserInfo(message)
        
        DispatchQueue.main.async {
            self.sentCount += 1
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchHeartRateManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("WCSessionのアクティベート失敗: \(error.localizedDescription)")
                self.isConnected = false
                return
            }
            self.isConnected = (activationState == .activated)
            print("WCSession 接続状態: \(self.isConnected)")
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        if let type = userInfo["type"] as? String, type == "selectUser",
           let userData = userInfo["user"] as? [String: Any] {
            handleUserSelection(userData)
        }
    }
    
    private func handleUserSelection(_ userData: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userData, options: [])
            let user = try JSONDecoder().decode(HeartUser.self, from: jsonData)
            
            DispatchQueue.main.async {
                self.currentUser = user
                print("ユーザー情報を受信: \(user.name)")
                // もし送信中だったら、新しい送信間隔を適用するためにタイマーを再起動
                if self.isSending {
                    self.stopSending()
                    self.startSending()
                }
            }
        } catch {
            print("ユーザーデータの解析に失敗: \(error)")
        }
    }
}

extension WatchHeartRateManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("ワークアウトセッション状態変更: \(toState.rawValue)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("ワークアウトセッションでエラー発生: \(error.localizedDescription)")
    }
}

extension WatchHeartRateManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard type == HKQuantityType.quantityType(forIdentifier: .heartRate) else { continue }
            
            if let statistics = workoutBuilder.statistics(for: type as! HKQuantityType),
               let mostRecentQuantity = statistics.mostRecentQuantity() {
                let heartRateUnit = HKUnit(from: "count/min")
                let heartRate = Int(mostRecentQuantity.doubleValue(for: heartRateUnit))
                updateHeartRate(heartRate)
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
}

//
// WatchHeartRateService.swift
// camp_vol5_ios
//
// Apple Watch との心拍数データ連携を管理するサービス
// ConnectivityManager を使用して Watch からの心拍数データを受信し、
// UI に公開するための ObservableObject として機能する
//

import Combine
import SwiftUI
import WatchConnectivity

class WatchHeartRateService: ObservableObject {
    @Published var latestHeartRate: Int = 0
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "接続待機中"

    private var connectivityManager: ConnectivityManager
    private var cancellables = Set<AnyCancellable>()

    init() {
        // ConnectivityManager のインスタンスを作成
        self.connectivityManager = ConnectivityManager()

        // ConnectivityManager からの心拍数データを監視
        setupConnectivityObserver()
    }

    private func setupConnectivityObserver() {
        // 心拍数の変更を監視
        connectivityManager.$heartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                self?.latestHeartRate = heartRate
            }
            .store(in: &cancellables)

        // 接続状態の変更を監視
        connectivityManager.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReachable in
                self?.isConnected = isReachable
                self?.connectionStatus = isReachable ? "Apple Watch接続済み" : "Apple Watch未接続"
            }
            .store(in: &cancellables)

        // 鼓動の通知を監視（必要に応じてアニメーションなどに使用）
        connectivityManager.heartbeatSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                // 鼓動に合わせた処理（アニメーションなど）
                self?.onHeartbeat()
            }
            .store(in: &cancellables)
    }

    // MARK: - Apple Watch連携用メソッド
    func sendUserToWatch(_ user: User) {
        guard connectivityManager.isReachable else {
            connectionStatus = "Apple Watchが接続されていません"
            return
        }

        // WCSessionを使ってユーザー情報をWatchに送信
        let userInfo: [String: Any] = [
            "type": "userInfo",
            "data": [
                "userId": user.id,
                "userName": user.name,
            ],
        ]

        if WCSession.default.isReachable {
            WCSession.default.transferUserInfo(userInfo)
            connectionStatus = "ユーザー情報をApple Watchに送信済み"
            print("Sending user \(user.name) to Apple Watch")
        }
    }

    func startHeartRateMonitoring() {
        guard connectivityManager.isReachable else {
            connectionStatus = "Apple Watchが接続されていません"
            return
        }

        // Watchに心拍数監視開始の指示を送信
        let message: [String: Any] = [
            "type": "startHeartRate"
        ]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                DispatchQueue.main.async {
                    self.connectionStatus = "心拍数監視開始エラー: \(error.localizedDescription)"
                }
            }
        }

        connectionStatus = "心拍数監視開始要求送信済み"
    }

    func stopHeartRateMonitoring() {
        // Watchに心拍数監視停止の指示を送信
        let message: [String: Any] = [
            "type": "stopHeartRate"
        ]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                DispatchQueue.main.async {
                    self.connectionStatus = "心拍数監視停止エラー: \(error.localizedDescription)"
                }
            }
        }

        connectionStatus = "心拍数監視停止"
        latestHeartRate = 0
    }

    func connectToWatch() {
        connectionStatus = "Apple Watchとの接続を確認中..."

        // WCSessionの状態を確認
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.activationState == .activated {
                connectionStatus = session.isReachable ? "Apple Watch接続済み" : "Apple Watchが見つかりません"
                isConnected = session.isReachable
            } else {
                connectionStatus = "WCSession が非アクティブです"
                isConnected = false
            }
        } else {
            connectionStatus = "WatchConnectivity がサポートされていません"
            isConnected = false
        }
    }

    // 鼓動に合わせた処理
    private func onHeartbeat() {
        print("Heartbeat detected")
    }

    // ConnectivityManager への直接アクセス（必要に応じて）
    var connectivity: ConnectivityManager {
        return connectivityManager
    }
}

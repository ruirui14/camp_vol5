//import SwiftUI
//import WatchConnectivity
//
//struct SettingsView: View {
//    // 親Viewから渡される認証情報を管理するViewModel
//    @EnvironmentObject var authViewModel: AuthViewModel
//    
//    // 既存のConnectivityManagerを直接使用
//    @EnvironmentObject var connectivityManager: ConnectivityManager
//    
//    // ハートアニメーション用のState
//    @State private var isBeating = false
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(spacing: 24) {
//                    // MARK: - ユーザー情報セクション
//                    userInfoSection
//                    
//                    // MARK: - 現在の心拍数カード
//                    heartRateCard
//                    
//                    // MARK: - 接続状態表示
//                    connectionStatusSection
//                    
//                    
//                    Spacer()
//                }
//                .padding()
//            }
//            .background(Color(.systemGroupedBackground))
//            .navigationTitle("設定")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("設定").font(.headline)
//                }
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button("サインアウト") {
//                        authViewModel.signOut()
//                    }
//                }
//            }
//            .toolbarBackground(Color.pink.opacity(0.9), for: .navigationBar)
//            .toolbarBackground(.visible, for: .navigationBar)
//            .toolbarColorScheme(.dark, for: .navigationBar)
//        }
//        .onAppear {
//            // View表示時にユーザー情報をWatchに送信
//            sendUserToWatch()
//        }
//        .onChange(of: authViewModel.currentUser) { _, newUser in
//            // ユーザーが変更されたらWatchに情報を送信
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                sendUserToWatch()
//            }
//        }
//        .onChange(of: connectivityManager.isReachable) { _, isReachable in
//            // 接続状態が変更されたら（接続された時に）ユーザー情報を送信
//            if isReachable {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                    sendUserToWatch()
//                }
//            }
//        }
//        .onChange(of: connectivityManager.heartRate) { _, newHeartRate in
//            // 心拍数が変更されたらアニメーションを発火
//            if newHeartRate > 0 {
//                isBeating = true
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
//                    isBeating = false
//                }
//            }
//        }
//    }
//    
//    // MARK: - ユーザー情報セクション
//    @ViewBuilder
//    private var userInfoSection: some View {
//        if let user = authViewModel.currentUser {
//            HStack(spacing: 16) {
//                Image(systemName: "person.circle.fill")
//                    .font(.system(size: 44))
//                    .foregroundColor(.gray)
//                Text(user.name)
//                    .font(.title2)
//                    .fontWeight(.bold)
//                Spacer()
//            }
//        } else {
//            ProgressView()
//                .padding()
//        }
//    }
//    
//    // MARK: - 心拍数カード
//    @ViewBuilder
//    private var heartRateCard: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("現在の心拍数")
//                .font(.headline)
//                .foregroundColor(.black.opacity(0.7))
//                .padding([.top, .leading])
//            
//            heartIcon
//                .padding(.bottom)
//        }
//        .frame(maxWidth: .infinity)
//        .background(Color.pink.opacity(0.1))
//        .cornerRadius(20)
//        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: connectivityManager.heartRate)
//    }
//    
//    // MARK: - ハートアイコンと心拍数
//    @ViewBuilder
//    private var heartIcon: some View {
//        ZStack {
//            // 通常時のハート（小さい）
//            Image("heart")
//                .renderingMode(.original)
//                .font(.system(size: 120))
//                .scaleEffect(isBeating ? 1.25 : 1.0)
//                .opacity(isBeating ? 0.0 : 1.0)
//            
//            // 鼓動時のハート（大きい・明るい）
//            Image("heart")
//                .renderingMode(.original)
//                .font(.system(size: 120))
//                .scaleEffect(isBeating ? 1.25 : 1.0)
//                .opacity(isBeating ? 1.0 : 0.0)
//                .shadow(color: .red, radius: 10, x: 0, y: 0) // 発光しているように見せる影
//            
//            // 中央の心拍数
//            if connectivityManager.heartRate > 0 {
//                Text("\(connectivityManager.heartRate)")
//                    .font(.system(size: 36, weight: .bold, design: .rounded))
//                    .foregroundColor(.white)
//                    .shadow(radius: 2)
//            } else {
//                Text("－")
//                    .font(.system(size: 36, weight: .bold, design: .rounded))
//                    .foregroundColor(.white.opacity(0.8))
//            }
//        }
//        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isBeating)
//        .frame(height: 100)
//        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: isBeating) { _, isBeatingNow in
//            return isBeatingNow
//        }
//    }
//    
//    // MARK: - 接続状態表示
//    @ViewBuilder
//    private var connectionStatusSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("接続状態")
//                .font(.headline)
//                .foregroundColor(.black.opacity(0.7))
//            
//            HStack {
//                Image(systemName: connectivityManager.isReachable ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
//                    .foregroundColor(connectivityManager.isReachable ? .green : .gray)
//                Text(connectivityManager.isReachable ? "Apple Watch接続中" : "接続待機中")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                Spacer()
//            }
//        }
//        .padding()
//        .background(Color(.systemBackground))
//        .cornerRadius(12)
//        .shadow(radius: 1)
//    }
//    
//    // MARK: - ヘルパーメソッド
//    private func sendUserToWatch() {
//        guard let user = authViewModel.currentUser else {
//            print("ユーザー情報がありません")
//            return
//        }
//        
//        guard connectivityManager.isReachable else {
//            print("Apple Watchが接続されていません")
//            return
//        }
//        
//        // ConnectivityManagerを使ってユーザー情報をWatchに送信
//        let userInfo: [String: Any] = [
//            "type": "userInfo",
//            "data": [
//                "userId": user.id,
//                "userName": user.name
//            ]
//        ]
//        
//        // WCSessionを使って送信
//        if WCSession.default.isReachable {
//            WCSession.default.transferUserInfo(userInfo)
//        } else {
//            print("WCSession.isReachable = false")
//        }
//    }
//}

import SwiftUI
import WatchConnectivity

struct SettingsView: View {
    // 親Viewから渡される認証情報を管理するViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // 既存のConnectivityManagerを直接使用
    @EnvironmentObject var connectivityManager: ConnectivityManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - ユーザー情報セクション
                    userInfoSection
                    
                    // MARK: - 現在の心拍数カード
                    heartRateCard
                    
                    // MARK: - 接続状態表示
                    connectionStatusSection
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("設定").font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("サインアウト") {
                        authViewModel.signOut()
                    }
                }
            }
            .toolbarBackground(Color.pink.opacity(0.9), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            // View表示時にユーザー情報をWatchに送信
            sendUserToWatch()
        }
        .onChange(of: authViewModel.currentUser) { _, newUser in
            // ユーザーが変更されたらWatchに情報を送信
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                sendUserToWatch()
            }
        }
        .onChange(of: connectivityManager.isReachable) { _, isReachable in
            // 接続状態が変更されたら（接続された時に）ユーザー情報を送信
            if isReachable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    sendUserToWatch()
                }
            }
        }
    }
    
    // MARK: - ユーザー情報セクション
    @ViewBuilder
    private var userInfoSection: some View {
        if let user = authViewModel.currentUser {
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.gray)
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
        } else {
            ProgressView()
                .padding()
        }
    }
    
    // MARK: - 心拍数カード（HeartAnimationView使用）
    @ViewBuilder
    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("現在の心拍数")
                .font(.headline)
                .foregroundColor(.black.opacity(0.7))
                .padding([.top, .leading])
            
            // ★ 新しいHeartAnimationViewコンポーネントを使用
            VStack(spacing: 8) {
                HeartAnimationView(
                    bpm: connectivityManager.heartRate,
                    heartSize: 100,
                    showBPM: true,
                    enableHaptic: true,
                    heartColor: .red
                )
                
                // 心拍数の状態テキスト
                if connectivityManager.heartRate > 0 {
                    Text("\(connectivityManager.heartRate) BPM")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("リアルタイム受信中")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("－ BPM")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("Apple Watchで測定を開始してください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.pink.opacity(0.1))
        .cornerRadius(20)
    }
    
    // MARK: - 接続状態表示
    @ViewBuilder
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("接続状態")
                .font(.headline)
                .foregroundColor(.black.opacity(0.7))
            
            // Apple Watch接続状態
            HStack {
                Image(systemName: connectivityManager.isReachable ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .foregroundColor(connectivityManager.isReachable ? .green : .gray)
                Text(connectivityManager.isReachable ? "Apple Watch接続中" : "接続待機中")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // 心拍数受信状態
            HStack {
                Image(systemName: connectivityManager.heartRate > 0 ? "waveform.path.ecg" : "waveform.path.ecg.rectangle")
                    .foregroundColor(connectivityManager.heartRate > 0 ? .green : .gray)
                Text(connectivityManager.heartRate > 0 ? "心拍数受信中" : "心拍数待機中")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    // MARK: - ヘルパーメソッド
    private func sendUserToWatch() {
        guard let user = authViewModel.currentUser else {
            print("ユーザー情報がありません")
            return
        }
        
        guard connectivityManager.isReachable else {
            print("Apple Watchが接続されていません")
            return
        }
        
        // ConnectivityManagerを使ってユーザー情報をWatchに送信
        let userInfo: [String: Any] = [
            "type": "userInfo",
            "data": [
                "userId": user.id,
                "userName": user.name
            ]
        ]
        
        // WCSessionを使って送信
        if WCSession.default.isReachable {
            WCSession.default.transferUserInfo(userInfo)
            print("✅ ユーザー情報をApple Watchに送信完了: \(user.name)")
        } else {
            print("❌ WCSession.isReachable = false")
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(ConnectivityManager())
}

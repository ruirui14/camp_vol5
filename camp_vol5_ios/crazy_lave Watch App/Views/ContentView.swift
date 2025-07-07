import SwiftUI

struct ContentView: View {
    @ObservedObject private var watchManager = WatchHeartRateManager.shared
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
                        .shadow(color: .red, radius: 10, x: 0, y: 0)
                    
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
                
                VStack(spacing: 2) {
                    Text("接続状態: \(watchManager.isConnected ? "接続中" : "未接続")")
                        .font(.caption2)
                        .foregroundColor(watchManager.isConnected ? .green : .red)
                }
                .padding(.vertical, 4)
                
                VStack {
                    Button(action: {
                        toggleSending()
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
                }
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            watchManager.setup()
        }
        .onDisappear {
            watchManager.cleanup()
        }
        .onReceive(watchManager.heartbeatSubject) { _ in
            triggerHeartbeat()
        }
    }
    
    private func toggleSending() {
        if watchManager.isSending {
            watchManager.stopSending()
        } else {
            watchManager.startSending()
        }
    }
    
    private func triggerHeartbeat() {
        isBeating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isBeating = false
        }
    }
    
    private func requestHealthKitPermission() {
        watchManager.setup()
    }
}

#Preview {
    ContentView()
}

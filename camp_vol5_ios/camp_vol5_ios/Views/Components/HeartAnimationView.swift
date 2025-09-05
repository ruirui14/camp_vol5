// Views/Components/HeartAnimationView.swift
// リアルタイムハートアニメーションコンポーネント - HRV対応の高精度心拍再現

import SwiftUI

struct HeartAnimationView: View {
    @StateObject private var viewModel = HeartAnimationViewModel()
    @ObservedObject private var vibrationService = VibrationService.shared

    // MARK: - カスタマイズ可能なプロパティ

    let heartSize: CGFloat
    let showBPM: Bool
    let enableHaptic: Bool
    let heartColor: Color
    let syncWithVibration: Bool

    // MARK: - アニメーション状態

    @State private var isBeating = false

    // MARK: - 外部から制御可能なBPM

    let bpm: Int

    init(
        bpm: Int,
        heartSize: CGFloat = 120,
        showBPM: Bool = true,
        enableHaptic: Bool = true,
        heartColor: Color = .red,
        syncWithVibration: Bool = false
    ) {
        self.bpm = bpm
        self.heartSize = heartSize
        self.showBPM = showBPM
        self.enableHaptic = enableHaptic
        self.heartColor = heartColor
        self.syncWithVibration = syncWithVibration
    }

    var body: some View {
        ZStack {
            // 通常時のハート
            heartImage
                .scaleEffect(isBeating ? 1.25 : 1.0)
                .opacity(isBeating ? 0.0 : 1.0)

            // 鼓動時のハート（発光効果付き）
            heartImage
                .scaleEffect(isBeating ? 1.25 : 1.0)
                .opacity(isBeating ? 1.0 : 0.0)
                .shadow(color: heartColor, radius: 10, x: 0, y: 0)

            // 中央のBPM表示
            if showBPM {
                bpmText
            }
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isBeating)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: isBeating) {
            _, isBeatingNow in
            enableHaptic ? isBeatingNow : false
        }
        .onChange(of: bpm) { _, newBPM in
            if newBPM > 0 && !syncWithVibration {
                viewModel.startSimulation(bpm: newBPM)
            } else {
                viewModel.stopSimulation()
            }
        }
        .onReceive(syncWithVibration ? vibrationService.heartbeatTrigger : viewModel.heartbeatSubject) { _ in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isBeating = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isBeating = false
                }
            }
        }
        .onAppear {
            if bpm > 0 && !syncWithVibration {
                viewModel.startSimulation(bpm: bpm)
            }
        }
        .onDisappear {
            viewModel.stopSimulation()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var heartImage: some View {
        if let heartUIImage = UIImage(named: "heart_beat") {
            Image(uiImage: heartUIImage)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: heartSize, height: heartSize * 0.876)  // 元のアスペクト比維持
                .clipShape(Circle())
        } else {
            // フォールバック: システムアイコン
            Image(systemName: "heart.fill")
                .font(.system(size: heartSize * 0.6))
                .foregroundColor(heartColor)
        }
    }

    @ViewBuilder
    private var bpmText: some View {
        if bpm > 0 {
            Text("\(bpm)")
                .font(.system(size: heartSize * 0.305, weight: .semibold))  // サイズに応じてフォントも調整
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.8), radius: 2, x: 0, y: 1)
        } else {
            Text("--")
                .font(.system(size: heartSize * 0.305, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.8), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - 便利なイニシャライザー

extension HeartAnimationView {
    /// 大きなハート用
    static func large(bpm: Int, showBPM: Bool = true, syncWithVibration: Bool = false) -> HeartAnimationView {
        HeartAnimationView(bpm: bpm, heartSize: 200, showBPM: showBPM, syncWithVibration: syncWithVibration)
    }

    /// 中サイズハート用
    static func medium(bpm: Int, showBPM: Bool = true, syncWithVibration: Bool = false) -> HeartAnimationView {
        HeartAnimationView(bpm: bpm, heartSize: 120, showBPM: showBPM, syncWithVibration: syncWithVibration)
    }

    /// 小さなハート用
    static func small(bpm: Int, showBPM: Bool = false, syncWithVibration: Bool = false) -> HeartAnimationView {
        HeartAnimationView(bpm: bpm, heartSize: 60, showBPM: showBPM, syncWithVibration: syncWithVibration)
    }

    /// カスタムカラー用
    static func custom(bpm: Int, size: CGFloat, color: Color, syncWithVibration: Bool = false) -> HeartAnimationView {
        HeartAnimationView(bpm: bpm, heartSize: size, heartColor: color, syncWithVibration: syncWithVibration)
    }
}

// MARK: - Preview

#Preview("大きなハート") {
    VStack(spacing: 30) {
        HeartAnimationView.large(bpm: 75)
        HeartAnimationView.medium(bpm: 82)
        HeartAnimationView.small(bpm: 90)
    }
    .padding()
    .background(Color.black.opacity(0.1))
}

// Views/SplashView.swift
// アプリ起動時に表示されるスプラッシュ画面
// Resource/splash-logoを画像を中央に配置し、初期化完了後にメイン画面に遷移

import RiveRuntime
import SwiftUI

struct SplashView: View {
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            MainAccentGradient()

            RiveViewModel(fileName: "splash-logo", fit: .scaleDown).view()
                .offset(x: offset)
                .rotationEffect(.degrees(rotation))

        }
        .onAppear {
            // 振動アニメーション
            startVibration()

            // 端末の触覚フィードバック
            startHapticFeedback()
        }
    }

    private func startVibration() {
        // ランダムな振動エフェクト
        withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: true)) {
            offset = CGFloat.random(in: -3...3)
            rotation = Double.random(in: -2...2)
        }
    }

    private func startHapticFeedback() {
        let duration: Double = 2.5
        let interval: Double = 0.5

        let impactStrong = UIImpactFeedbackGenerator(style: .heavy)
        impactStrong.prepare()

        for i in 0...Int(duration / interval) {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                impactStrong.impactOccurred(intensity: 1.0)
            }
        }
    }
}

#Preview {
    SplashView()
}

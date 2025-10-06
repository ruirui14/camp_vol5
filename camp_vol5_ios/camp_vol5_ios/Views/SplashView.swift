// Views/SplashView.swift
// アプリ起動時に表示されるスプラッシュ画面
// kyouai画像を中央に配置し、初期化完了後にメイン画面に遷移

import RiveRuntime
import SwiftUI

struct SplashView: View {
    @Binding var isActive: Bool
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0
    private let transition: Double = 3.5

    var body: some View {
        ZStack {
            MainAccentGradient()

            RiveViewModel(fileName: "splash-logo", fit: .scaleDown).view()
                .offset(x: offset)
                .rotationEffect(.degrees(rotation))

        }
        .onAppear {
            // フェードインアニメーション
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }

            // 振動アニメーション
            startVibration()

            // 端末の触覚フィードバック
            startHapticFeedback()

            // 1.5秒後にメイン画面に遷移
            DispatchQueue.main.asyncAfter(deadline: .now() + transition) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isActive = false
                }
            }
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
        let interval: Double = 0.5

        let impactStrong = UIImpactFeedbackGenerator(style: .heavy)
        impactStrong.prepare()

        for i in 0...Int(transition / interval) {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                impactStrong.impactOccurred(intensity: 1.0)
            }
        }
    }
}

#Preview {
    SplashView(isActive: .constant(false))
}

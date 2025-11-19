// Views/Auth/Components/HeartbeatAnimation.swift
// ハートビートアニメーション
// 波紋効果とパルス効果を持つハートアイコンアニメーション

import SwiftUI

struct HeartbeatAnimation: View {
    let isAnimating: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            // 外側の円（波紋効果）
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .scaleEffect(pulse ? 1.8 : 1.0)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.5),
                        value: pulse
                    )
            }

            // グラスモーフィズム背景
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .pink.opacity(0.5), radius: 20, x: 0, y: 10)

            // ハートアイコン
            Image(systemName: "heart.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(Color.accent)
                .scaleEffect(pulse ? 1.15 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: pulse
                )
                .shadow(color: Color.accent.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .onAppear {
            pulse = true
        }
    }
}

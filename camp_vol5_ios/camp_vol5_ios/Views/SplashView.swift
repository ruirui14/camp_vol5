// Views/SplashView.swift
// アプリ起動時に表示されるスプラッシュ画面
// kyouai画像を中央に配置し、初期化完了後にメイン画面に遷移

import SwiftUI

struct SplashView: View {
    @Binding var isActive: Bool
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            MainAccentGradient()

            Image("kyouai")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .opacity(opacity)
        }
        .onAppear {
            // フェードインアニメーション
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }

            // 1.5秒後にメイン画面に遷移
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isActive = false
                }
            }
        }
    }
}

#Preview {
    SplashView(isActive: .constant(false))
}

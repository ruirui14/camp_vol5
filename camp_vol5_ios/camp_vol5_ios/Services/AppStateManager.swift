// Services/AppStateManager.swift
// アプリケーション全体の状態管理を行うマネージャー
// スプラッシュ画面からメイン画面への遷移を制御

import Foundation
import SwiftUI

/// アプリケーションの状態を定義
enum AppState {
    case splash  // スプラッシュ画面
    case main  // メイン画面
}

/// アプリケーション状態を管理するマネージャー
@MainActor
class AppStateManager: ObservableObject {
    @Published var currentState: AppState = .splash

    // スプラッシュ画面の最小表示時間（秒）
    private let minimumSplashDuration: TimeInterval = 2.5

    init() {
        Task {
            await initialize()
        }
    }

    /// アプリケーションの初期化処理
    private func initialize() async {
        // スプラッシュ画面の最小表示時間を確保（UX向上）
        try? await Task.sleep(nanoseconds: UInt64(minimumSplashDuration * 1_000_000_000))

        // メイン画面に遷移
        withAnimation(.easeOut(duration: 0.3)) {
            currentState = .main
        }
    }
}

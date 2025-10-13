// Services/Protocols/VibrationServiceProtocol.swift
// VibrationServiceのプロトコル定義 - 依存性注入とテスタビリティのため

import Combine
import Foundation

/// バイブレーション制御を行うサービスのプロトコル
@MainActor
protocol VibrationServiceProtocol: ObservableObject {
    /// バイブレーション実行中かどうか
    var isVibrating: Bool { get }

    /// 心拍に合わせたバイブレーションを開始
    /// - Parameter bpm: 心拍数（BPM）
    func startHeartbeatVibration(bpm: Int)

    /// バイブレーションを停止
    func stopVibration()

    /// BPMの妥当性をチェック
    /// - Parameter bpm: 心拍数（BPM）
    /// - Returns: 妥当なBPMの場合true
    func isValidBPM(_ bpm: Int) -> Bool
}

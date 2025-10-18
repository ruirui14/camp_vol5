// Models/Heartbeat.swift
// 心拍データを表すデータモデル
// 純粋なデータ構造のみ - データ変換ロジックはRepositoryで実行

import Foundation

struct Heartbeat: Codable, Identifiable, Equatable {
    var id = UUID()
    let userId: String
    let bpm: Int
    let timestamp: Date

    init(userId: String, bpm: Int, timestamp: Date = Date()) {
        self.userId = userId
        self.bpm = bpm
        self.timestamp = timestamp
    }
}

// Firebase 送信用の軽量データ
struct HeartbeatData: Codable {
    let bpm: Int
    let timestamp: TimeInterval

    init(from heartbeat: Heartbeat) {
        bpm = heartbeat.bpm
        timestamp = heartbeat.timestamp.timeIntervalSince1970 * 1000
    }

    init(bpm: Int) {
        self.bpm = bpm
        timestamp = Date().timeIntervalSince1970 * 1000
    }

    func toDictionary() -> [String: Any] {
        return [
            "bpm": bpm,
            "timestamp": timestamp
        ]
    }
}

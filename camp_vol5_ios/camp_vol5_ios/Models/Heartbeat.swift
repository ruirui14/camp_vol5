// Models/Heartbeat.swift
// 心拍データを表すデータモデル
// Firebase操作はHeartbeatServiceで実行される

import Firebase
import FirebaseDatabase
import Foundation

struct Heartbeat: Codable, Identifiable {
    var id = UUID()
    let userId: String
    let bpm: Int
    let timestamp: Date

    init(userId: String, bpm: Int, timestamp: Date = Date()) {
        self.userId = userId
        self.bpm = bpm
        self.timestamp = timestamp
    }

    // Realtime Database データから初期化
    init?(from data: [String: Any], userId: String) {
        guard let bpm = data["bpm"] as? Int,
            let timestamp = data["timestamp"] as? TimeInterval
        else {
            return nil
        }

        self.userId = userId
        self.bpm = bpm
        self.timestamp = Date(timeIntervalSince1970: timestamp / 1000)
    }
}

// Firebase 送信用の軽量データ
struct HeartbeatData: Codable {
    let bpm: Int
    let timestamp: TimeInterval

    init(from heartbeat: Heartbeat) {
        self.bpm = heartbeat.bpm
        self.timestamp = heartbeat.timestamp.timeIntervalSince1970 * 1000
    }

    init(bpm: Int) {
        self.bpm = bpm
        self.timestamp = Date().timeIntervalSince1970 * 1000
    }

    func toDictionary() -> [String: Any] {
        return [
            "bpm": bpm,
            "timestamp": timestamp,
        ]
    }
}


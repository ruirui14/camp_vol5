// Models/Heartbeat.swift
// 心拍データを表すデータモデル
// 純粋なデータ構造のみ - データ変換ロジックはRepositoryで実行

import Foundation

struct Heartbeat: Codable, Identifiable, Equatable {
    var id = UUID()
    let userId: String
    let bpm: Int  // bpmは必須
    let timestamp: Date?  // timestampが空の場合にも対応するためOptionalに変更

    init(userId: String, bpm: Int, timestamp: Date? = Date()) {
        self.userId = userId
        self.bpm = bpm
        self.timestamp = timestamp
    }
}

// Firebase 送信用の軽量データ
struct HeartbeatData: Codable {
    let bpm: Int
    let timestamp: TimeInterval?

    init(from heartbeat: Heartbeat) {
        bpm = heartbeat.bpm
        if let ts = heartbeat.timestamp {
            timestamp = ts.timeIntervalSince1970 * 1000
        } else {
            timestamp = nil
        }
    }

    init(bpm: Int, timestamp: Date? = Date()) {
        self.bpm = bpm
        if let ts = timestamp {
            self.timestamp = ts.timeIntervalSince1970 * 1000
        } else {
            self.timestamp = nil
        }
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "bpm": bpm
        ]
        if let timestamp = timestamp {
            dict["timestamp"] = timestamp
        }
        return dict
    }
}

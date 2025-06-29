// Models/User.swift
import FirebaseFirestore
import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let inviteCode: String  // UUIDv4
    let allowQRRegistration: Bool
    let followingUserIds: [String]
    let createdAt: Date?
    let updatedAt: Date?

    // Firestore用の初期化
    init(
        id: String,
        name: String,
        inviteCode: String = UUID().uuidString,
        allowQRRegistration: Bool = true,
        followingUserIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.allowQRRegistration = allowQRRegistration
        self.followingUserIds = followingUserIds
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Firestore データから初期化
    init?(from data: [String: Any], id: String) {
        guard let name = data["name"] as? String,
            let inviteCode = data["inviteCode"] as? String,
            let allowQRRegistration = data["allowQRRegistration"] as? Bool,
            let followingUserIds = data["followingUserIds"] as? [String]
        else {
            return nil
        }

        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.allowQRRegistration = allowQRRegistration
        self.followingUserIds = followingUserIds

        if let createdAtTimestamp = data["createdAt"] as? Timestamp {
            self.createdAt = createdAtTimestamp.dateValue()
        } else {
            self.createdAt = nil
        }

        if let updatedAtTimestamp = data["updatedAt"] as? Timestamp {
            self.updatedAt = updatedAtTimestamp.dateValue()
        } else {
            self.updatedAt = nil
        }
    }

    // Firestore保存用辞書に変換
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "inviteCode": inviteCode,
            "allowQRRegistration": allowQRRegistration,
            "followingUserIds": followingUserIds,
            "createdAt": Timestamp(date: createdAt ?? Date()),
            "updatedAt": Timestamp(date: updatedAt ?? Date()),
        ]
    }
}

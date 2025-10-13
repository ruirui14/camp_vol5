import FirebaseDatabase
import Foundation

struct HeartUser: Codable, Equatable {
    let id: String
    var name: String

    var dictionary: [String: Any] {
        return ["id": id, "name": name]
    }

    static func from(dictionary: [String: Any]) -> HeartUser? {
        guard let id = dictionary["id"] as? String,
            let name = dictionary["name"] as? String
        else { return nil }

        return HeartUser(id: id, name: name)
    }
}

// Watchから受信するデータ
struct HeartRateData: Codable {
    let heartNum: Int
    let timestamp: TimeInterval
    let userId: String
}

// Firebaseから受信するリアルタイムデータ
struct HeartRateRealtimeData: Codable {
    let heartNum: Int
    let timestamp: TimeInterval
    let userId: String
}

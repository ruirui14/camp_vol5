import Foundation

// MARK: - Data Models
struct User: Identifiable, Equatable, Codable {
    let id: String
    var name: String
    var inviteCode: String
    var allowQRRegistration: Bool
    
    init(id: String, name: String, inviteCode: String, allowQRRegistration: Bool) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.allowQRRegistration = allowQRRegistration
    }
    
    init?(id: String, data: [String: Any]) {
        guard let name = data["name"] as? String else {
            return nil
        }
        self.id = id
        self.name = name
        self.inviteCode = data["inviteCode"] as? String ?? ""
        self.allowQRRegistration = data["allowQRRegistration"] as? Bool ?? false
    }
    
    var dictionaryRepresentation: [String: Any] {
        return [
            "id": id, // AuthのUIDも保存しておく
            "name": name,
            "inviteCode": inviteCode,
            "allowQRRegistration": allowQRRegistration
        ]
    }
    
    // 空のユーザーインスタンスを提供
    static var empty: User {
        return User(
            id: "",
            name: "",
            inviteCode: "",
            allowQRRegistration: false
        )
    }
}

// Services/FirebaseConfig.swift
import Firebase

class FirebaseConfig {
    static let shared = FirebaseConfig()

    private init() {}

    func configure() {
        FirebaseApp.configure()
    }
}

// Services/FirebaseConfig.swift
import Firebase
import FirebaseFirestore

class FirebaseConfig {
    static let shared = FirebaseConfig()

    private init() {}

    func configure() {
        // Firebaseアプリの初期化
        FirebaseApp.configure()

        // Firestore Persistence設定
        configureFirestorePersistence()
    }

    /// Firestoreのオフラインキャッシングを有効化
    private func configureFirestorePersistence() {
        let db = Firestore.firestore()
        let settings = FirestoreSettings()

        // オフライン永続化を有効化
        settings.isPersistenceEnabled = true

        // キャッシュサイズを無制限に設定
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited)

        db.settings = settings
    }
}

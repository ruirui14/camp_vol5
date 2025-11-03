// Repositories/FirestoreUserRepository.swift
// Firestoreを使用したUserRepositoryの実装
// データ変換ロジック（Model ↔ Firestore）をここに集約

import Combine
import Firebase
import FirebaseFirestore
import FirebasePerformance
import Foundation

/// FirestoreベースのUserRepository実装
class FirestoreUserRepository: UserRepositoryProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Public Methods

    func create(userId: String, name: String) -> AnyPublisher<User, Error> {
        let trace = PerformanceMonitor.shared.startTrace(PerformanceMonitor.DataTrace.createUser)

        return Future { [weak self] promise in
            guard let self = self else {
                PerformanceMonitor.shared.stopTrace(trace)
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            let user = User(
                id: userId,
                name: name,
                inviteCode: UUID().uuidString,
                allowQRRegistration: false,
                createdAt: Date(),
                updatedAt: Date()
            )

            let firestoreData = self.toFirestore(user)

            // メインのユーザードキュメントを作成
            self.db.collection("users").document(userId).setData(firestoreData) { error in
                if let error = error {
                    PerformanceMonitor.shared.stopTrace(trace)
                    promise(.failure(error))
                    return
                }

                // タイムスタンプをprivate/metadataに保存
                self.db
                    .collection("users")
                    .document(userId)
                    .collection("private")
                    .document("metadata")
                    .setData([
                        "created_at": FieldValue.serverTimestamp(),
                        "updated_at": FieldValue.serverTimestamp(),
                    ]) { metadataError in
                        PerformanceMonitor.shared.stopTrace(trace)
                        if let metadataError = metadataError {
                            promise(.failure(metadataError))
                        } else {
                            promise(.success(user))
                        }
                    }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetch(userId: String) -> AnyPublisher<User?, Error> {
        let trace = PerformanceMonitor.shared.startTrace(PerformanceMonitor.DataTrace.fetchUser)

        return Future { [weak self] promise in
            guard let self = self else {
                PerformanceMonitor.shared.stopTrace(trace)
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users").document(userId).getDocument { snapshot, error in
                PerformanceMonitor.shared.stopTrace(trace)
                if let error = error {
                    promise(.failure(error))
                } else if let data = snapshot?.data() {
                    let user = self.fromFirestore(data, userId: userId)
                    promise(.success(user))
                } else {
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func update(_ user: User) -> AnyPublisher<Void, Error> {
        let trace = PerformanceMonitor.shared.startTrace(PerformanceMonitor.DataTrace.updateUser)

        return Future { [weak self] promise in
            guard let self = self else {
                PerformanceMonitor.shared.stopTrace(trace)
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            let updateData = self.toFirestore(user)

            // メインのユーザードキュメントを更新
            self.db.collection("users").document(user.id).updateData(updateData) { error in
                if let error = error {
                    PerformanceMonitor.shared.stopTrace(trace)
                    promise(.failure(error))
                    return
                }

                // private/metadataのupdated_atを更新
                self.db
                    .collection("users")
                    .document(user.id)
                    .collection("private")
                    .document("metadata")
                    .updateData([
                        "updated_at": FieldValue.serverTimestamp()
                    ]) { metadataError in
                        PerformanceMonitor.shared.stopTrace(trace)
                        if let metadataError = metadataError {
                            promise(.failure(metadataError))
                        } else {
                            promise(.success(()))
                        }
                    }
            }
        }
        .eraseToAnyPublisher()
    }

    func delete(userId: String) -> AnyPublisher<Void, Error> {
        let trace = PerformanceMonitor.shared.startTrace(PerformanceMonitor.DataTrace.deleteUser)

        return Future { [weak self] promise in
            guard let self = self else {
                PerformanceMonitor.shared.stopTrace(trace)
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users").document(userId).delete { error in
                PerformanceMonitor.shared.stopTrace(trace)
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func findByInviteCode(_ inviteCode: String) -> AnyPublisher<User?, Error> {
        let trace = PerformanceMonitor.shared.startTrace(
            PerformanceMonitor.DataTrace.findUserByInviteCode)

        return Future { [weak self] promise in
            guard let self = self else {
                PerformanceMonitor.shared.stopTrace(trace)
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users")
                .whereField("inviteCode", isEqualTo: inviteCode)
                .whereField("allowQRRegistration", isEqualTo: true)
                .getDocuments { snapshot, error in
                    PerformanceMonitor.shared.stopTrace(trace)
                    if let error = error {
                        promise(.failure(error))
                    } else if let document = snapshot?.documents.first {
                        let userId = document.documentID
                        let user = self.fromFirestore(document.data(), userId: userId)
                        promise(.success(user))
                    } else {
                        promise(.success(nil))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    func fetchMultiple(userIds: [String]) -> AnyPublisher<[User], Error> {
        guard !userIds.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let trace = PerformanceMonitor.shared.startTrace(
            PerformanceMonitor.DataTrace.fetchMultipleUsers)

        return Future { [weak self] promise in
            guard let self = self else {
                PerformanceMonitor.shared.stopTrace(trace)
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users")
                .whereField("id", in: userIds)
                .getDocuments { snapshot, error in
                    PerformanceMonitor.shared.stopTrace(trace)
                    if let error = error {
                        promise(.failure(error))
                    } else if let documents = snapshot?.documents {
                        let users = documents.compactMap { doc in
                            self.fromFirestore(doc.data(), userId: doc.documentID)
                        }
                        promise(.success(users))
                    } else {
                        promise(.success([]))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private: Data Transformation

    /// UserをFirestoreデータに変換
    /// 注意: createdAtとupdatedAtはprivate/metadataに別途保存されるため、ここには含めない
    private func toFirestore(_ user: User) -> [String: Any] {
        return [
            "id": user.id,
            "name": user.name,
            "inviteCode": user.inviteCode,
            "allowQRRegistration": user.allowQRRegistration,
        ]
    }

    /// FirestoreデータをUserに変換
    private func fromFirestore(_ data: [String: Any], userId: String) -> User? {
        guard let name = data["name"] as? String,
            let inviteCode = data["inviteCode"] as? String,
            let allowQRRegistration = data["allowQRRegistration"] as? Bool
        else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        let maxConnections = data["maxConnections"] as? Int
        let maxConnectionsUpdatedAt = (data["maxConnectionsUpdatedAt"] as? Timestamp)?.dateValue()

        return User(
            id: userId,
            name: name,
            inviteCode: inviteCode,
            allowQRRegistration: allowQRRegistration,
            createdAt: createdAt,
            updatedAt: updatedAt,
            maxConnections: maxConnections,
            maxConnectionsUpdatedAt: maxConnectionsUpdatedAt
        )
    }

    func fetchMaxConnectionsRanking(limit: Int) -> AnyPublisher<[User], Error> {
        let trace = PerformanceMonitor.shared.startTrace(
            PerformanceMonitor.DataTrace.fetchMaxConnectionsRanking)

        return Future { [weak self] promise in
            guard let self = self else {
                PerformanceMonitor.shared.stopTrace(trace)
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            let queryStartTime = Date()

            self.db.collection("users")
                .whereField("maxConnections", isGreaterThan: 0)
                .order(by: "maxConnections", descending: true)
                .limit(to: limit)
                .getDocuments { snapshot, error in
                    let queryDuration = Date().timeIntervalSince(queryStartTime)

                    // クエリ実行時間をメトリクスに記録
                    if let trace = trace {
                        PerformanceMonitor.shared.setAttribute(
                            trace,
                            key: "limit",
                            value: String(limit)
                        )
                        PerformanceMonitor.shared.incrementMetric(
                            trace,
                            key: "query_duration_ms",
                            by: Int64(queryDuration * 1000)
                        )
                    }

                    PerformanceMonitor.shared.stopTrace(trace)

                    if let error = error {
                        print("❌ ランキング取得エラー: \(error.localizedDescription)")
                        promise(.failure(error))
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("⚠️ ランキングデータが空です")
                        promise(.success([]))
                        return
                    }

                    let users = documents.compactMap { document -> User? in
                        self.fromFirestore(document.data(), userId: document.documentID)
                    }

                    print(
                        "✅ ランキング取得成功: \(users.count)件 (クエリ時間: \(String(format: "%.2f", queryDuration * 1000))ms)"
                    )

                    promise(.success(users))
                }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case serviceUnavailable
    case dataCorrupted
    case notFound

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "サービスが利用できません"
        case .dataCorrupted:
            return "データが破損しています"
        case .notFound:
            return "データが見つかりません"
        }
    }
}

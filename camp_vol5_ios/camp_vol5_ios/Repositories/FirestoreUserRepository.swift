// Repositories/FirestoreUserRepository.swift
// Firestoreを使用したUserRepositoryの実装
// データ変換ロジック（Model ↔ Firestore）をここに集約

import Combine
import Firebase
import FirebaseFirestore
import Foundation

/// FirestoreベースのUserRepository実装
class FirestoreUserRepository: UserRepositoryProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Public Methods

    func create(userId: String, name: String) -> AnyPublisher<User, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            let user = User(
                id: userId,
                name: name,
                inviteCode: UUID().uuidString,
                allowQRRegistration: false,
                followingUserIds: [],
                createdAt: Date(),
                updatedAt: Date()
            )

            let firestoreData = self.toFirestore(user)

            self.db.collection("users").document(userId).setData(firestoreData) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetch(userId: String) -> AnyPublisher<User?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users").document(userId).getDocument { snapshot, error in
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
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            var updateData = self.toFirestore(user)
            updateData["updatedAt"] = Timestamp(date: Date())

            self.db.collection("users").document(user.id).updateData(updateData) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func delete(userId: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users").document(userId).delete { error in
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
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users")
                .whereField("inviteCode", isEqualTo: inviteCode)
                .whereField("allowQRRegistration", isEqualTo: true)
                .getDocuments { snapshot, error in
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

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users")
                .whereField("id", in: userIds)
                .getDocuments { snapshot, error in
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
    private func toFirestore(_ user: User) -> [String: Any] {
        var dict: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "inviteCode": user.inviteCode,
            "allowQRRegistration": user.allowQRRegistration,
            "followingUserIds": user.followingUserIds,
        ]

        if let createdAt = user.createdAt {
            dict["createdAt"] = Timestamp(date: createdAt)
        }

        if let updatedAt = user.updatedAt {
            dict["updatedAt"] = Timestamp(date: updatedAt)
        }

        return dict
    }

    /// FirestoreデータをUserに変換
    private func fromFirestore(_ data: [String: Any], userId: String) -> User? {
        guard let name = data["name"] as? String,
            let inviteCode = data["inviteCode"] as? String,
            let allowQRRegistration = data["allowQRRegistration"] as? Bool,
            let followingUserIds = data["followingUserIds"] as? [String]
        else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()

        return User(
            id: userId,
            name: name,
            inviteCode: inviteCode,
            allowQRRegistration: allowQRRegistration,
            followingUserIds: followingUserIds,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
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

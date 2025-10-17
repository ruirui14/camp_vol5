// Repositories/FirestoreFollowingRepository.swift
// Firestoreを使用したFollowingRepositoryの実装
// データ変換ロジック（Model ↔ Firestore）をここに集約

import Combine
import Firebase
import FirebaseFirestore
import Foundation

/// FirestoreベースのFollowingRepository実装
/// users/{userId}/following サブコレクションを使用
class FirestoreFollowingRepository: FollowingRepositoryProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Public Methods

    func addFollowing(userId: String, following: Following) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            let firestoreData = self.toFirestore(following)

            self.db.collection("users")
                .document(userId)
                .collection("following")
                .document(following.followingId)
                .setData(firestoreData) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    func removeFollowing(userId: String, followingId: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users")
                .document(userId)
                .collection("following")
                .document(followingId)
                .delete { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    func fetchFollowings(userId: String) -> AnyPublisher<[Following], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users")
                .document(userId)
                .collection("following")
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let documents = snapshot?.documents {
                        let followings = documents.compactMap { doc in
                            self.fromFirestore(doc.data(), followingId: doc.documentID)
                        }
                        promise(.success(followings))
                    } else {
                        promise(.success([]))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private: Data Transformation

    /// FollowingをFirestoreデータに変換
    private func toFirestore(_ following: Following) -> [String: Any] {
        var dict: [String: Any] = [
            "followingId": following.followingId
        ]

        if let createdAt = following.createdAt {
            dict["createdAt"] = Timestamp(date: createdAt)
        }

        return dict
    }

    /// FirestoreデータをFollowingに変換
    private func fromFirestore(_ data: [String: Any], followingId: String) -> Following? {
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()

        return Following(
            id: followingId,
            followingId: followingId,
            createdAt: createdAt
        )
    }
}

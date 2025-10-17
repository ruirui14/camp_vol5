// Repositories/FirestoreFollowerRepository.swift
// Firestoreを使用したFollowerRepositoryの実装
// データ変換ロジック（Model ↔ Firestore）をここに集約

import Combine
import Firebase
import FirebaseFirestore
import Foundation

/// FirestoreベースのFollowerRepository実装
/// users/{userId}/followers サブコレクションを使用
class FirestoreFollowerRepository: FollowerRepositoryProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Public Methods

    func addFollower(userId: String, follower: Follower) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            let firestoreData = self.toFirestore(follower)

            self.db.collection("users")
                .document(userId)
                .collection("followers")
                .document(follower.followerId)
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

    func removeFollower(userId: String, followerId: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users")
                .document(userId)
                .collection("followers")
                .document(followerId)
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

    func fetchFollowers(userId: String) -> AnyPublisher<[Follower], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users")
                .document(userId)
                .collection("followers")
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let documents = snapshot?.documents {
                        let followers = documents.compactMap { doc in
                            self.fromFirestore(doc.data(), followerId: doc.documentID)
                        }
                        promise(.success(followers))
                    } else {
                        promise(.success([]))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    func updateNotificationSetting(
        userId: String,
        followerId: String,
        enabled: Bool
    ) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users")
                .document(userId)
                .collection("followers")
                .document(followerId)
                .updateData(["notificationEnabled": enabled]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    func updateFCMToken(
        userId: String,
        followerId: String,
        fcmToken: String
    ) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.db.collection("users")
                .document(userId)
                .collection("followers")
                .document(followerId)
                .updateData(["fcmToken": fcmToken]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private: Data Transformation

    /// FollowerをFirestoreデータに変換
    private func toFirestore(_ follower: Follower) -> [String: Any] {
        var dict: [String: Any] = [
            "followerId": follower.followerId,
            "notificationEnabled": follower.notificationEnabled,
        ]

        if let fcmToken = follower.fcmToken {
            dict["fcmToken"] = fcmToken
        }

        if let createdAt = follower.createdAt {
            dict["createdAt"] = Timestamp(date: createdAt)
        }

        return dict
    }

    /// FirestoreデータをFollowerに変換
    private func fromFirestore(_ data: [String: Any], followerId: String) -> Follower? {
        guard let notificationEnabled = data["notificationEnabled"] as? Bool else {
            return nil
        }

        let fcmToken = data["fcmToken"] as? String
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()

        return Follower(
            id: followerId,
            followerId: followerId,
            fcmToken: fcmToken,
            notificationEnabled: notificationEnabled,
            createdAt: createdAt
        )
    }
}

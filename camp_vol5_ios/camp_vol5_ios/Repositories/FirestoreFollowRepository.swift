// Repositories/FirestoreFollowRepository.swift
// Firestore Batch Writeを使用したフォロー操作の実装
// following と followers コレクションへの書き込みをアトミックに実行
// データ整合性を保証（全て成功 or 全て失敗）

import Combine
import Firebase
import FirebaseFirestore
import Foundation

/// FirestoreベースのFollowRepository実装
/// Batch Writeを使用してフォロー/アンフォロー操作のアトミック性を保証
class FirestoreFollowRepository: FollowRepositoryProtocol {
    private let db: Firestore
    private let logger = FirebaseLogger.shared

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Public Methods

    /// フォロー操作をBatch Writeで実行
    /// following と followers の両方を同時に書き込み
    func followUser(
        currentUserId: String,
        targetUserId: String,
        fcmToken: String?
    ) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.logger.log("Starting batch follow: \(currentUserId) -> \(targetUserId)")

            let batch = self.db.batch()

            // 1. followingコレクションに追加（自分 → フォロー先）
            let followingRef = self.db.collection("users")
                .document(currentUserId)
                .collection("following")
                .document(targetUserId)

            let followingData: [String: Any] = [
                "followingId": targetUserId,
                "createdAt": Timestamp(date: Date()),
            ]
            batch.setData(followingData, forDocument: followingRef)

            // 2. followersコレクションに追加（フォロー先 → 自分）
            let followerRef = self.db.collection("users")
                .document(targetUserId)
                .collection("followers")
                .document(currentUserId)

            var followerData: [String: Any] = [
                "followerId": currentUserId,
                "notificationEnabled": true,
                "createdAt": Timestamp(date: Date()),
            ]
            if let fcmToken = fcmToken {
                followerData["fcmToken"] = fcmToken
            }
            batch.setData(followerData, forDocument: followerRef)

            // 3. バッチコミット（アトミック実行）
            batch.commit { error in
                if let error = error {
                    self.logger.error("Batch follow failed: \(error.localizedDescription)")
                    promise(.failure(error))
                } else {
                    self.logger.log("Batch follow succeeded: \(currentUserId) -> \(targetUserId)")
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// アンフォロー操作をBatch Writeで実行
    /// following と followers の両方を同時に削除
    func unfollowUser(
        currentUserId: String,
        targetUserId: String
    ) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            self.logger.log("Starting batch unfollow: \(currentUserId) -> \(targetUserId)")

            let batch = self.db.batch()

            // 1. followingコレクションから削除（自分 → フォロー先）
            let followingRef = self.db.collection("users")
                .document(currentUserId)
                .collection("following")
                .document(targetUserId)
            batch.deleteDocument(followingRef)

            // 2. followersコレクションから削除（フォロー先 → 自分）
            let followerRef = self.db.collection("users")
                .document(targetUserId)
                .collection("followers")
                .document(currentUserId)
            batch.deleteDocument(followerRef)

            // 3. バッチコミット（アトミック実行）
            batch.commit { error in
                if let error = error {
                    self.logger.error("Batch unfollow failed: \(error.localizedDescription)")
                    promise(.failure(error))
                } else {
                    self.logger.log(
                        "Batch unfollow succeeded: \(currentUserId) -> \(targetUserId)")
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

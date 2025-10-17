// Services/NotificationService.swift
// FCMトークン管理とプッシュ通知設定のビジネスロジック
// Firebase Cloud Messaging (FCM) との連携

import Combine
import Firebase
import FirebaseMessaging
import Foundation

/// FCMトークン管理サービス
class NotificationService: NSObject, NotificationServiceProtocol {
    private let followerRepository: FollowerRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var _currentFCMToken: String?

    var currentFCMToken: String? {
        return _currentFCMToken
    }

    init(followerRepository: FollowerRepositoryProtocol) {
        self.followerRepository = followerRepository
        super.init()

        // FCMトークンの更新を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fcmTokenRefreshed),
            name: .MessagingRegistrationTokenRefreshed,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    func registerFCMToken(userId: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NotificationError.serviceUnavailable))
                return
            }

            // FCMトークンを取得
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("❌ FCMトークン取得エラー: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }

                guard let token = token else {
                    promise(.failure(NotificationError.tokenUnavailable))
                    return
                }

                // トークンをキャッシュ
                self._currentFCMToken = token
                print("✅ FCMトークン取得成功: \(token)")

                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }

    func updateFCMTokenForFollowings(
        followingIds: [String],
        currentUserId: String
    ) -> AnyPublisher<Void, Error> {
        guard let fcmToken = _currentFCMToken else {
            return Fail(error: NotificationError.tokenUnavailable)
                .eraseToAnyPublisher()
        }

        // 全てのフォロー先のfollowersコレクションを更新
        let publishers = followingIds.map { followingId in
            self.followerRepository.updateFCMToken(
                userId: followingId,
                followerId: currentUserId,
                fcmToken: fcmToken
            )
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    @objc private func fcmTokenRefreshed() {
        // トークンが更新されたら再取得
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("❌ FCMトークン再取得エラー: \(error.localizedDescription)")
                return
            }

            if let token = token {
                self?._currentFCMToken = token
                print("✅ FCMトークン更新: \(token)")
            }
        }
    }
}

// MARK: - Notification Errors

enum NotificationError: LocalizedError {
    case serviceUnavailable
    case tokenUnavailable

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "通知サービスが利用できません"
        case .tokenUnavailable:
            return "FCMトークンが取得できません"
        }
    }
}

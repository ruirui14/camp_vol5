// Services/UserService.swift
// ユーザー関連のビジネスロジックを提供するサービス
// データアクセスはRepositoryレイヤーに委譲

import Combine
import Foundation

// MARK: - UserService Protocol

protocol UserServiceProtocol {
    func createUser(uid: String, name: String) -> AnyPublisher<User, Error>
    func getUser(uid: String) -> AnyPublisher<User?, Error>
    func updateUser(_ user: User) -> AnyPublisher<Void, Error>
    func findUserByInviteCode(_ inviteCode: String) -> AnyPublisher<User?, Error>
    func getFollowingUsers(userId: String) -> AnyPublisher<[User], Error>
    func followUser(currentUserId: String, targetUserId: String) -> AnyPublisher<Void, Error>
    func unfollowUser(currentUserId: String, targetUserId: String) -> AnyPublisher<Void, Error>
    func generateNewInviteCode(for user: User) -> AnyPublisher<String, Error>
    func updateQRRegistrationSetting(for user: User, allow: Bool) -> AnyPublisher<Void, Error>
    func deleteUser(userId: String) -> AnyPublisher<Void, Error>
}

// MARK: - UserService Errors

enum UserServiceError: LocalizedError {
    case userNotFound
    case invalidInviteCode
    case repositoryError(Error)
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "ユーザーが見つかりません"
        case .invalidInviteCode:
            return "無効な招待コードです"
        case .repositoryError(let error):
            return "データベースエラー: \(error.localizedDescription)"
        case .serviceUnavailable:
            return "サービスが使用できません"
        }
    }
}

// MARK: - UserService Implementation

class UserService: UserServiceProtocol {
    static let shared: UserService = {
        let followerRepository = FirestoreFollowerRepository()
        let notificationService = NotificationService(followerRepository: followerRepository)
        return UserService(
            repository: FirestoreUserRepository(),
            followerRepository: followerRepository,
            followingRepository: FirestoreFollowingRepository(),
            followRepository: FirestoreFollowRepository(),
            notificationService: notificationService
        )
    }()

    private let repository: UserRepositoryProtocol
    private let followerRepository: FollowerRepositoryProtocol
    private let followingRepository: FollowingRepositoryProtocol
    private let followRepository: FollowRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let logger = FirebaseLogger.shared

    init(
        repository: UserRepositoryProtocol,
        followerRepository: FollowerRepositoryProtocol,
        followingRepository: FollowingRepositoryProtocol,
        followRepository: FollowRepositoryProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.repository = repository
        self.followerRepository = followerRepository
        self.followingRepository = followingRepository
        self.followRepository = followRepository
        self.notificationService = notificationService
    }

    // MARK: - User Management

    func createUser(uid: String, name: String) -> AnyPublisher<User, Error> {
        logger.log("Creating user: \(name) with ID: \(uid)")

        return repository.create(userId: uid, name: name)
            .handleEvents(
                receiveOutput: { [weak self] _ in
                    self?.logger.log("Successfully created user: \(name)")
                },
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.logger.error("Failed to create user: \(error.localizedDescription)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }

    func getUser(uid: String) -> AnyPublisher<User?, Error> {
        return repository.fetch(userId: uid)
            .eraseToAnyPublisher()
    }

    func updateUser(_ user: User) -> AnyPublisher<Void, Error> {
        return repository.update(user)
            .eraseToAnyPublisher()
    }

    // MARK: - Invite Code Management

    func findUserByInviteCode(_ inviteCode: String) -> AnyPublisher<User?, Error> {
        return repository.findByInviteCode(inviteCode)
            .eraseToAnyPublisher()
    }

    func generateNewInviteCode(for user: User) -> AnyPublisher<String, Error> {
        let newInviteCode = UUID().uuidString

        let updatedUser = User(
            id: user.id,
            name: user.name,
            inviteCode: newInviteCode,
            allowQRRegistration: user.allowQRRegistration,
            createdAt: user.createdAt,
            updatedAt: Date()
        )

        return repository.update(updatedUser)
            .map { newInviteCode }
            .eraseToAnyPublisher()
    }

    // MARK: - Follow Management

    func followUser(currentUserId: String, targetUserId: String) -> AnyPublisher<Void, Error> {
        // FCMトークンを取得
        let fcmToken = notificationService.currentFCMToken

        // Batch Writeでアトミックに実行（データ整合性を保証）
        return followRepository.followUser(
            currentUserId: currentUserId,
            targetUserId: targetUserId,
            fcmToken: fcmToken
        )
        .eraseToAnyPublisher()
    }

    func unfollowUser(currentUserId: String, targetUserId: String) -> AnyPublisher<Void, Error> {
        // Batch Writeでアトミックに実行（データ整合性を保証）
        return followRepository.unfollowUser(
            currentUserId: currentUserId,
            targetUserId: targetUserId
        )
        .eraseToAnyPublisher()
    }

    func getFollowingUsers(userId: String) -> AnyPublisher<[User], Error> {
        // followingコレクションからフォロー先IDを取得
        return followingRepository.fetchFollowings(userId: userId)
            .flatMap { [weak self] followings -> AnyPublisher<[User], Error> in
                guard let self = self else {
                    return Fail(error: UserServiceError.serviceUnavailable).eraseToAnyPublisher()
                }

                let followingIds = followings.map { $0.followingId }

                guard !followingIds.isEmpty else {
                    return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
                }

                return self.repository.fetchMultiple(userIds: followingIds)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Settings

    func updateQRRegistrationSetting(for user: User, allow: Bool) -> AnyPublisher<Void, Error> {
        let updatedUser = User(
            id: user.id,
            name: user.name,
            inviteCode: user.inviteCode,
            allowQRRegistration: allow,
            createdAt: user.createdAt,
            updatedAt: Date()
        )

        return repository.update(updatedUser)
            .eraseToAnyPublisher()
    }

    func deleteUser(userId: String) -> AnyPublisher<Void, Error> {
        return repository.delete(userId: userId)
            .eraseToAnyPublisher()
    }
}

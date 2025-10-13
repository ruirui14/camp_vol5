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
    func getFollowingUsers(followingUserIds: [String]) -> AnyPublisher<[User], Error>
    func followUser(currentUser: User, targetUserId: String) -> AnyPublisher<Void, Error>
    func unfollowUser(currentUser: User, targetUserId: String) -> AnyPublisher<Void, Error>
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
    static let shared = UserService()

    private let repository: UserRepositoryProtocol
    private let logger = FirebaseLogger.shared

    init(repository: UserRepositoryProtocol = FirestoreUserRepository()) {
        self.repository = repository
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
            followingUserIds: user.followingUserIds,
            createdAt: user.createdAt,
            updatedAt: Date()
        )

        return repository.update(updatedUser)
            .map { newInviteCode }
            .eraseToAnyPublisher()
    }

    // MARK: - Follow Management

    func followUser(currentUser: User, targetUserId: String) -> AnyPublisher<Void, Error> {
        var updatedFollowingIds = currentUser.followingUserIds
        if !updatedFollowingIds.contains(targetUserId) {
            updatedFollowingIds.append(targetUserId)
        }

        let updatedUser = User(
            id: currentUser.id,
            name: currentUser.name,
            inviteCode: currentUser.inviteCode,
            allowQRRegistration: currentUser.allowQRRegistration,
            followingUserIds: updatedFollowingIds,
            createdAt: currentUser.createdAt,
            updatedAt: Date()
        )

        return repository.update(updatedUser)
            .eraseToAnyPublisher()
    }

    func unfollowUser(currentUser: User, targetUserId: String) -> AnyPublisher<Void, Error> {
        let updatedFollowingIds = currentUser.followingUserIds.filter { $0 != targetUserId }

        let updatedUser = User(
            id: currentUser.id,
            name: currentUser.name,
            inviteCode: currentUser.inviteCode,
            allowQRRegistration: currentUser.allowQRRegistration,
            followingUserIds: updatedFollowingIds,
            createdAt: currentUser.createdAt,
            updatedAt: Date()
        )

        return repository.update(updatedUser)
            .eraseToAnyPublisher()
    }

    func getFollowingUsers(followingUserIds: [String]) -> AnyPublisher<[User], Error> {
        guard !followingUserIds.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        return repository.fetchMultiple(userIds: followingUserIds)
            .eraseToAnyPublisher()
    }

    // MARK: - Settings

    func updateQRRegistrationSetting(for user: User, allow: Bool) -> AnyPublisher<Void, Error> {
        let updatedUser = User(
            id: user.id,
            name: user.name,
            inviteCode: user.inviteCode,
            allowQRRegistration: allow,
            followingUserIds: user.followingUserIds,
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

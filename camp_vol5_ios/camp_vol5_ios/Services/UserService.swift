// Services/UserService.swift
// Firestoreを使用したユーザー関連のCRUD操作を提供するサービス

import Combine
import Firebase
import FirebaseFirestore
import Foundation

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User Management

    /// ユーザーを新規作成する
    func createUser(uid: String, name: String) -> AnyPublisher<User, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
                        )))
                return
            }

            let user = User(id: uid, name: name)

            self.db.collection("users").document(uid).setData(user.toDictionary()) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// ユーザー情報を取得する
    func getUser(uid: String) -> AnyPublisher<User?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
                        )))
                return
            }

            self.db.collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                } else if let data = snapshot?.data() {
                    let user = User(from: data, id: uid)
                    promise(.success(user))
                } else {
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// ユーザー情報を更新する
    func updateUser(_ user: User) -> AnyPublisher<User, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
                        )))
                return
            }

            let updateData: [String: Any] = [
                "name": user.name,
                "inviteCode": user.inviteCode,
                "allowQRRegistration": user.allowQRRegistration,
                "followingUserIds": user.followingUserIds,
                "updatedAt": Timestamp(date: Date()),
            ]

            self.db.collection("users").document(user.id).updateData(updateData) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    var updatedUser = user
                    // ここでupdatedAtを更新した新しいUserインスタンスを作成する必要があるが、
                    // Userが構造体なので直接変更できない。代わりに元のuserを返す
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Invite Code Management

    /// 招待コードでユーザーを検索する
    func findUserByInviteCode(_ inviteCode: String) -> AnyPublisher<User?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
                        )))
                return
            }

            self.db.collection("users")
                .whereField("inviteCode", isEqualTo: inviteCode)
                .whereField("allowQRRegistration", isEqualTo: true)
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let documents = snapshot?.documents, !documents.isEmpty {
                        let data = documents.first!.data()
                        let userId = documents.first!.documentID
                        let user = User(from: data, id: userId)
                        promise(.success(user))
                    } else {
                        promise(.success(nil))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    /// 新しい招待コードを生成する
    func generateNewInviteCode(for user: User) -> AnyPublisher<String, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
                        )))
                return
            }

            let newInviteCode = UUID().uuidString

            let updateData: [String: Any] = [
                "inviteCode": newInviteCode,
                "updatedAt": Timestamp(date: Date()),
            ]

            self.db.collection("users").document(user.id).updateData(updateData) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(newInviteCode))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Follow Management

    /// ユーザーをフォローする
    func followUser(currentUser: User, targetUserId: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
                        )))
                return
            }

            var updatedFollowingIds = currentUser.followingUserIds
            if !updatedFollowingIds.contains(targetUserId) {
                updatedFollowingIds.append(targetUserId)
            }

            let updateData: [String: Any] = [
                "followingUserIds": updatedFollowingIds,
                "updatedAt": Timestamp(date: Date()),
            ]

            self.db.collection("users").document(currentUser.id).updateData(updateData) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// ユーザーのフォローを解除する
    func unfollowUser(currentUser: User, targetUserId: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
                        )))
                return
            }

            let updatedFollowingIds = currentUser.followingUserIds.filter { $0 != targetUserId }

            let updateData: [String: Any] = [
                "followingUserIds": updatedFollowingIds,
                "updatedAt": Timestamp(date: Date()),
            ]

            self.db.collection("users").document(currentUser.id).updateData(updateData) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// フォロー中のユーザーリストを取得する
    func getFollowingUsers(followingUserIds: [String]) -> AnyPublisher<[User], Error> {
        guard !followingUserIds.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
                        )))
                return
            }

            self.db.collection("users")
                .whereField("id", in: followingUserIds)
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let documents = snapshot?.documents {
                        let users = documents.compactMap { doc in
                            User(from: doc.data(), id: doc.documentID)
                        }
                        promise(.success(users))
                    } else {
                        promise(.success([]))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Settings

    /// QR登録設定を更新する
    func updateQRRegistrationSetting(for user: User, allow: Bool) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
                        )))
                return
            }

            let updateData: [String: Any] = [
                "allowQRRegistration": allow,
                "updatedAt": Timestamp(date: Date()),
            ]

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

    /// ユーザーを削除する
    func deleteUser(userId: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(
                    .failure(
                        NSError(
                            domain: "UserService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]
                        )))
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
}

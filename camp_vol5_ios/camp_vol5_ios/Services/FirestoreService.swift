// Services/FirestoreService.swift
import Combine
import Firebase
import FirebaseFirestore

class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - User Management

    // ユーザー作成
    func createUser(uid: String, name: String) -> AnyPublisher<User, Error> {
        return Future { [weak self] promise in
            let user = User(id: uid, name: name)

            self?.db.collection("users").document(uid).setData(
                user.toDictionary()
            ) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // ユーザー情報取得
    func getUser(uid: String) -> AnyPublisher<User?, Error> {
        return Future { [weak self] promise in
            self?.db.collection("users").document(uid).getDocument {
                snapshot,
                error in
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

    // ユーザー情報更新
    func updateUser(_ user: User) -> AnyPublisher<User, Error> {
        return Future { [weak self] promise in
            var userData = user.toDictionary()
            userData["updatedAt"] = Timestamp()

            self?.db.collection("users").document(user.id).setData(userData) {
                error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Invite Code Management

    // 招待コードでユーザー検索
    func findUserByInviteCode(_ inviteCode: String) -> AnyPublisher<
        User?, Error
    > {
        return Future { [weak self] promise in
            self?.db.collection("users")
                .whereField("inviteCode", isEqualTo: inviteCode)
                .whereField("allowQRRegistration", isEqualTo: true)
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let document = snapshot?.documents.first {
                        let user = User(
                            from: document.data(),
                            id: document.documentID
                        )
                        promise(.success(user))
                    } else {
                        promise(.success(nil))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // 新しい招待コード生成
    func generateNewInviteCode(for userId: String) -> AnyPublisher<
        String, Error
    > {
        return Future { [weak self] promise in
            let newInviteCode = UUID().uuidString
            let updateData = [
                "inviteCode": newInviteCode,
                "updatedAt": Timestamp(),
            ]

            self?.db.collection("users").document(userId).updateData(updateData)
            { error in
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

    // ユーザーをフォロー
    func followUser(followerId: String, followeeId: String) -> AnyPublisher<
        Void, Error
    > {
        return Future { [weak self] promise in
            self?.db.collection("users").document(followerId).updateData([
                "followingUserIds": FieldValue.arrayUnion([followeeId]),
                "updatedAt": Timestamp(),
            ]) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // ユーザーのフォローを解除
    func unfollowUser(followerId: String, followeeId: String) -> AnyPublisher<
        Void, Error
    > {
        return Future { [weak self] promise in
            self?.db.collection("users").document(followerId).updateData([
                "followingUserIds": FieldValue.arrayRemove([followeeId]),
                "updatedAt": Timestamp(),
            ]) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // フォロー中のユーザー情報取得
    func getFollowingUsers(userId: String) -> AnyPublisher<[User], Error> {
        return getUser(uid: userId)
            .flatMap { [weak self] user -> AnyPublisher<[User], Error> in
                guard let user = user, !user.followingUserIds.isEmpty else {
                    return Just([]).setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }

                return self?.getUsers(userIds: user.followingUserIds)
                    ?? Just([]).setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // 複数ユーザー情報取得
    private func getUsers(userIds: [String]) -> AnyPublisher<[User], Error> {
        return Future { [weak self] promise in
            self?.db.collection("users")
                .whereField("id", in: userIds)
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        let users =
                            snapshot?.documents.compactMap { doc in
                                User(from: doc.data(), id: doc.documentID)
                            } ?? []
                        promise(.success(users))
                    }
                }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Settings

    // QR登録許可設定の変更
    func updateQRRegistrationSetting(userId: String, allowQRRegistration: Bool)
        -> AnyPublisher<
            Void, Error
        >
    {
        return Future { [weak self] promise in
            self?.db.collection("users").document(userId).updateData([
                "allowQRRegistration": allowQRRegistration,
                "updatedAt": Timestamp(),
            ]) { error in
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

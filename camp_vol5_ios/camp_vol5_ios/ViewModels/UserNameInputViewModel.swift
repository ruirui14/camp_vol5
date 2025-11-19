// ViewModels/UserNameInputViewModel.swift
// 認証後のユーザー名入力画面用ViewModel
// ユーザー作成・更新ロジックを管理

import Combine
import Foundation
import SwiftUI

enum SelectedAuthMethod {
    case none
    case anonymous
    case google
    case email
}

@MainActor
class UserNameInputViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published var userName: String = ""

    // MARK: - Properties

    let selectedAuthMethod: SelectedAuthMethod

    // MARK: - Dependencies

    private var authenticationManager: AuthenticationManager
    private let userService: UserServiceProtocol

    // MARK: - Initialization

    init(
        selectedAuthMethod: SelectedAuthMethod,
        authenticationManager: AuthenticationManager,
        userService: UserServiceProtocol = UserService.shared
    ) {
        self.selectedAuthMethod = selectedAuthMethod
        self.authenticationManager = authenticationManager
        self.userService = userService
        super.init()
        loadInitialUserName()
    }

    // MARK: - Actions

    func saveUserName() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateUserName(trimmedName) else { return }

        setLoading(true)
        clearError()

        switch selectedAuthMethod {
        case .none:
            // 認証メソッドが選択されていない場合は何もしない
            setLoading(false)
        case .anonymous:
            handleAnonymousUserSave(name: trimmedName)
        case .google, .email:
            handleAuthenticatedUserSave(name: trimmedName)
        }
    }

    func goBackToAuth() {
        // 認証状態をリセット
        authenticationManager.needsUserNameInput = false
        authenticationManager.selectedAuthMethod = "anonymous"

        // 認証ユーザーがいる場合はサインアウト
        if authenticationManager.isAuthenticated {
            authenticationManager.signOut()
        }

        // エラーメッセージをクリア
        authenticationManager.clearError()

        print("🔥 Going back to auth screen")
    }

    // MARK: - Private Methods

    private func validateUserName(_ name: String) -> Bool {
        if name.isEmpty {
            handleError(
                NSError(
                    domain: "UserNameInputViewModel",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "表示名を入力してください"]
                )
            )
            return false
        }

        if name.count > 20 {
            handleError(
                NSError(
                    domain: "UserNameInputViewModel",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "表示名は20文字以内で入力してください"]
                )
            )
            return false
        }

        return true
    }

    private func loadInitialUserName() {
        if !isAnonymousUser {
            // Google/Email認証の場合、既存の表示名を初期値として設定
            if let displayName = authenticationManager.user?.displayName,
                !displayName.isEmpty
            {
                userName = displayName
            } else {
                // Firestoreから既存のユーザー情報を取得して表示名を設定
                guard let uid = authenticationManager.user?.uid else { return }

                userService.getUser(uid: uid)
                    .handleErrors(on: self)
                    .compactMap { $0 }
                    .sink { [weak self] existingUser in
                        guard let self = self, self.userName.isEmpty else { return }
                        self.userName = existingUser.name
                    }
                    .store(in: &cancellables)
            }
        }
    }

    private func handleAnonymousUserSave(name: String) {
        guard let uid = authenticationManager.user?.uid else {
            handleSaveError("認証エラーが発生しました")
            return
        }

        // 匿名ユーザーをFirestoreに保存
        userService.createUser(uid: uid, name: name)
            .handleErrors(on: self)
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.handleUserSaveSuccess(user)
            }
            .store(in: &cancellables)
    }

    private func handleAuthenticatedUserSave(name: String) {
        guard let uid = authenticationManager.user?.uid else {
            handleSaveError("認証エラーが発生しました")
            return
        }

        // 既存ユーザーをチェック
        userService.getUser(uid: uid)
            .handleErrors(on: self)
            .sink { [weak self] existingUser in
                if let existingUser = existingUser {
                    // 既存ユーザーの名前を更新
                    self?.updateExistingUser(existingUser, newName: name)
                } else {
                    // 既存ユーザーが見つからない場合、新規作成
                    self?.createNewUser(uid: uid, name: name)
                }
            }
            .store(in: &cancellables)
    }

    private func createNewUser(uid: String, name: String) {
        userService.createUser(uid: uid, name: name)
            .handleErrors(on: self)
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.handleUserSaveSuccess(user)
            }
            .store(in: &cancellables)
    }

    private func updateExistingUser(_ existingUser: User, newName: String) {
        let updatedUser = User(
            id: existingUser.id,
            name: newName,
            inviteCode: existingUser.inviteCode,
            allowQRRegistration: existingUser.allowQRRegistration,
            createdAt: existingUser.createdAt,
            updatedAt: Date()
        )

        userService.updateUser(updatedUser)
            .handleErrors(on: self)
            .sink { [weak self] _ in
                self?.handleUserSaveSuccess(updatedUser)
            }
            .store(in: &cancellables)
    }

    private func handleUserSaveSuccess(_ user: User) {
        authenticationManager.currentUser = user
        authenticationManager.completeUserNameInput()
        setLoading(false)
    }

    private func handleSaveError(_ message: String) {
        handleError(
            NSError(
                domain: "UserNameInputViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        )
    }

    // MARK: - Computed Properties

    var isAnonymousUser: Bool {
        selectedAuthMethod == .anonymous
    }

    var headerTitle: String {
        "プロフィール設定"
    }

    var headerSubtitle: String {
        userName.isEmpty ? "表示名を入力してください" : "表示名を確認・変更してください"
    }

    var buttonTitle: String {
        isLoading ? "保存中..." : "完了"
    }

    var isFormValid: Bool {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName.count <= 20 && !isLoading
    }

    var buttonColors: [Color] {
        if isFormValid {
            return [Color.green, Color.green.opacity(0.8)]
        } else {
            return [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]
        }
    }

    var showHelpText: Bool {
        isAnonymousUser
    }

    var helpText: String {
        "後でプロフィールから変更できます"
    }
}

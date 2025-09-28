// ViewModels/UserNameInputViewModel.swift
// 認証後のユーザー名入力画面用ViewModel
// ユーザー作成・更新ロジックを管理

import Combine
import Foundation
import SwiftUI

enum SelectedAuthMethod {
    case anonymous
    case google
    case email
}

@MainActor
class UserNameInputViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userName: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Properties
    let selectedAuthMethod: SelectedAuthMethod

    // MARK: - Dependencies
    private var authenticationManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()

    init(selectedAuthMethod: SelectedAuthMethod, authenticationManager: AuthenticationManager) {
        self.selectedAuthMethod = selectedAuthMethod
        self.authenticationManager = authenticationManager
        loadInitialUserName()
    }

    func updateAuthenticationManager(_ authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        cancellables.removeAll()
    }

    // MARK: - Actions

    func saveUserName() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateUserName(trimmedName) else { return }

        isLoading = true
        errorMessage = nil

        switch selectedAuthMethod {
        case .anonymous:
            handleAnonymousUserSave(name: trimmedName)
        case .google, .email:
            handleAuthenticatedUserSave(name: trimmedName)
        }
    }

    func clearError() {
        errorMessage = nil
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
            errorMessage = "表示名を入力してください"
            return false
        }

        if name.count > 20 {
            errorMessage = "表示名は20文字以内で入力してください"
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

                UserService.shared.getUser(uid: uid)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { [weak self] existingUser in
                            if let existingUser = existingUser,
                               let self = self,
                               self.userName.isEmpty {
                                self.userName = existingUser.name
                            }
                        }
                    )
                    .store(in: &cancellables)
            }
        }
    }

    private func handleAnonymousUserSave(name: String) {
        guard let uid = authenticationManager.user?.uid else {
            handleError("認証エラーが発生しました")
            return
        }

        // 匿名ユーザーをFirestoreに保存
        UserService.shared.createUser(uid: uid, name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.handleError("保存に失敗しました: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] user in
                    self?.handleUserSaveSuccess(user)
                }
            )
            .store(in: &cancellables)
    }

    private func handleAuthenticatedUserSave(name: String) {
        guard let uid = authenticationManager.user?.uid else {
            handleError("認証エラーが発生しました")
            return
        }

        // 既存ユーザーをチェック
        UserService.shared.getUser(uid: uid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(_) = completion {
                        // 既存ユーザーが見つからない場合、新規作成
                        self?.createNewUser(uid: uid, name: name)
                    }
                },
                receiveValue: { [weak self] existingUser in
                    if let existingUser = existingUser {
                        // 既存ユーザーの名前を更新
                        self?.updateExistingUser(existingUser, newName: name)
                    } else {
                        // 既存ユーザーが見つからない場合、新規作成
                        self?.createNewUser(uid: uid, name: name)
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func createNewUser(uid: String, name: String) {
        UserService.shared.createUser(uid: uid, name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.handleError("保存に失敗しました: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] user in
                    self?.handleUserSaveSuccess(user)
                }
            )
            .store(in: &cancellables)
    }

    private func updateExistingUser(_ existingUser: User, newName: String) {
        let updatedUser = User(
            id: existingUser.id,
            name: newName,
            inviteCode: existingUser.inviteCode,
            allowQRRegistration: existingUser.allowQRRegistration,
            followingUserIds: existingUser.followingUserIds,
            imageName: existingUser.imageName
        )

        UserService.shared.updateUser(updatedUser)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.handleError("更新に失敗しました: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.handleUserSaveSuccess(updatedUser)
                }
            )
            .store(in: &cancellables)
    }

    private func handleUserSaveSuccess(_ user: User) {
        authenticationManager.currentUser = user
        authenticationManager.completeUserNameInput()
        isLoading = false
    }

    private func handleError(_ message: String) {
        errorMessage = message
        isLoading = false
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
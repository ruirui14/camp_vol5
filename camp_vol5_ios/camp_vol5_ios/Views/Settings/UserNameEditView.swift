// Views/Settings/UserNameEditView.swift
// ユーザー名編集画面 - ユーザー名の変更機能を提供
// SwiftUIベストプラクティスに従い、状態管理とバリデーションを実装

import Combine
import SwiftUI

struct UserNameEditView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var newUserName: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(
                header: Text("新しいユーザー名"),
                footer: Text("ユーザー名は20文字以内で入力してください")
            ) {
                TextField("新しいユーザー名", text: $newUserName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(isLoading)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            Section {
                Button(action: updateUserName) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.white)
                        }

                        Text(isLoading ? "更新中..." : "ユーザー名を更新")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .disabled(
                    isLoading || newUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
                .opacity(
                    newUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
        }
        .navigationTitle("ユーザー名変更")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            newUserName = viewModel.currentUser?.name ?? ""
        }
        .alert("成功", isPresented: .constant(successMessage != nil)) {
            Button("OK") {
                successMessage = nil
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            if let successMessage = successMessage {
                Text(successMessage)
            }
        }
    }

    private func updateUserName() {
        let trimmedName = newUserName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "ユーザー名を入力してください"
            return
        }

        guard trimmedName.count <= 20 else {
            errorMessage = "ユーザー名は20文字以内で入力してください"
            return
        }

        guard let currentUser = viewModel.currentUser else {
            errorMessage = "ユーザー情報が取得できません"
            return
        }

        isLoading = true
        errorMessage = nil

        // 新しいユーザー情報を作成
        let updatedUser = User(
            id: currentUser.id,
            name: trimmedName,
            inviteCode: currentUser.inviteCode,
            allowQRRegistration: currentUser.allowQRRegistration,
            createdAt: currentUser.createdAt,
            updatedAt: Date()
        )

        // UserServiceを使ってユーザー情報を更新
        UserService.shared.updateUser(updatedUser)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case let .failure(error) = completion {
                        self.errorMessage = "更新に失敗しました: \(error.localizedDescription)"
                    }
                },
                receiveValue: { _ in
                    self.viewModel.currentUser = updatedUser
                    self.successMessage = "ユーザー名を更新しました"
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    NavigationStack {
        UserNameEditView(
            viewModel: SettingsViewModel(authenticationManager: AuthenticationManager())
        )
    }
}

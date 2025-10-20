// Views/UserNameInputView.swift
// 認証後のユーザー名入力画面

import SwiftUI

struct UserNameInputView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: UserNameInputViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        selectedAuthMethod: SelectedAuthMethod = .anonymous,
        factory: ViewModelFactory
    ) {
        self._viewModel = StateObject(
            wrappedValue: factory.makeUserNameInputViewModel(
                selectedAuthMethod: selectedAuthMethod
            )
        )
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // 背景グラデーション
                MainAccentGradient()

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 60)

                        // ヘッダー
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

                            VStack(spacing: 8) {
                                Text(viewModel.headerTitle)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Text(viewModel.headerSubtitle)
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                            }
                        }

                        // 入力フォーム
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("表示名")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                TextField("あなたの名前", text: $viewModel.userName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.body)
                                    .autocapitalization(.words)
                                    .disableAutocorrection(true)
                                    .frame(height: 44)
                            }

                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                                    .multilineTextAlignment(.center)
                            }

                            // 保存ボタン
                            Button(action: { viewModel.saveUserName() }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                    }

                                    Text(viewModel.buttonTitle)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(
                                        colors: viewModel.buttonColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .disabled(!viewModel.isFormValid)

                            if viewModel.showHelpText {
                                Text(viewModel.helpText)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 32)

                        Spacer()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { viewModel.goBackToAuth() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("戻る")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(20)
                }
            }
        }
    }
}

#Preview {
    let authManager = AuthenticationManager()
    let factory = ViewModelFactory(
        authenticationManager: authManager,
        userService: UserService.shared,
        heartbeatService: HeartbeatService.shared,
        vibrationService: VibrationService.shared
    )
    return UserNameInputView(
        selectedAuthMethod: .anonymous,
        factory: factory
    )
    .environmentObject(authManager)
    .environmentObject(factory)
}

// Views/SettingsView.swift
// 設定画面のメインビュー - 各設定項目へのナビゲーションを提供
// 抽出されたコンポーネントを使用して簡潔で保守性の高い実装を実現

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var autoLockManager = AutoLockManager.shared
    @Environment(\.presentationMode) var presentationMode

    init() {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                authenticationManager: AuthenticationManager()
            )
        )
    }

    var body: some View {
        GeometryReader { geometry in
            Form {
                if authenticationManager.isAuthenticated {
                    SettingsNavigationSection(
                        viewModel: viewModel,
                        autoLockManager: autoLockManager
                    )

                    SettingsSignOutSection {
                        viewModel.signOut()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                SettingsToolbar {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .overlay(alignment: .top) {
                NavigationBarGradient(safeAreaHeight: geometry.safeAreaInsets.top)
            }
            .onAppear {
                viewModel.updateAuthenticationManager(authenticationManager)
                if authenticationManager.isAuthenticated {
                    viewModel.loadCurrentUser()
                }
            }
            .refreshable {
                if authenticationManager.isAuthenticated {
                    viewModel.loadCurrentUser()
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert(
                "成功",
                isPresented: .constant(viewModel.successMessage != nil)
            ) {
                Button("OK") {
                    viewModel.clearSuccessMessage()
                }
            } message: {
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                }
            }
            .onChange(of: authenticationManager.isAuthenticated) { isAuthenticated in
                // 認証状態が失われた場合（アカウント削除など）は設定画面を閉じる
                if !isAuthenticated {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthenticationManager())
    }
}

// ViewModels/Base/BaseViewModel.swift
// すべてのViewModelの基底クラス - 共通機能を提供

import Combine
import Foundation

/// すべてのViewModelの基底クラス
/// 共通のエラーハンドリング、ローディング状態、Combine購読管理を提供
@MainActor
class BaseViewModel: ObservableObject {
    // MARK: - Published Properties

    /// ローディング中かどうか
    @Published var isLoading = false

    /// エラーメッセージ
    @Published var errorMessage: String?

    /// 成功メッセージ
    @Published var successMessage: String?

    // MARK: - Protected Properties

    /// Combine購読の保持
    var cancellables = Set<AnyCancellable>()

    // MARK: - Error Handling

    /// エラーを処理してエラーメッセージを設定
    /// - Parameter error: 発生したエラー
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoading = false
    }

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Success Handling

    /// 成功メッセージを設定
    /// - Parameter message: 表示する成功メッセージ
    func setSuccessMessage(_ message: String) {
        successMessage = message
    }

    /// 成功メッセージをクリア
    func clearSuccessMessage() {
        successMessage = nil
    }

    // MARK: - Loading State

    /// ローディング状態を設定
    /// - Parameter isLoading: ローディング中かどうか
    func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    // MARK: - Lifecycle

    deinit {
        cancellables.removeAll()
    }
}

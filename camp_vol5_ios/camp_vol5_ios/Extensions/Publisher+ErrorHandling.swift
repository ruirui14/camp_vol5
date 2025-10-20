// Extensions/Publisher+ErrorHandling.swift
// Combineパブリッシャーのエラーハンドリング統一拡張

import Combine
import Foundation

extension Publisher {
    /// ViewModelでのエラーハンドリングを簡潔に行うための拡張
    /// エラーが発生した場合、ViewModelのhandleError()を呼び出し、Neverストリームに変換
    ///
    /// - Parameter viewModel: エラーハンドリングを行うViewModel
    /// - Returns: エラーを処理済みのNeverパブリッシャー
    @MainActor
    func handleErrors(
        on viewModel: BaseViewModel
    ) -> AnyPublisher<Output, Never> {
        self
            .receive(on: DispatchQueue.main)
            .catch { error -> Empty<Output, Never> in
                viewModel.handleError(error)
                return Empty()
            }
            .eraseToAnyPublisher()
    }

    /// ViewModelでのエラーハンドリングを行い、デフォルト値を返す拡張
    ///
    /// - Parameters:
    ///   - viewModel: エラーハンドリングを行うViewModel
    ///   - defaultValue: エラー時に返すデフォルト値
    /// - Returns: エラーを処理済みのNeverパブリッシャー
    @MainActor
    func handleErrors(
        on viewModel: BaseViewModel,
        defaultValue: Output
    ) -> AnyPublisher<Output, Never> {
        self
            .receive(on: DispatchQueue.main)
            .catch { error -> Just<Output> in
                viewModel.handleError(error)
                return Just(defaultValue)
            }
            .eraseToAnyPublisher()
    }

    /// エラーをログに記録するための拡張
    ///
    /// - Parameter context: ログのコンテキスト情報
    /// - Returns: エラーログ済みのパブリッシャー
    func logErrors(context: String = "") -> Publishers.HandleEvents<Self> {
        handleEvents(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                _ = print("❌ Error in \(context): \(error.localizedDescription)")
            }
        })
    }
}

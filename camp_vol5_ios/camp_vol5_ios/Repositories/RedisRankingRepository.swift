// Repositories/RedisRankingRepository.swift
// Upstash Redis REST APIを使用したランキングデータ取得
// 従量課金プラン使用（フォールバックなし）
// Firebase Remote Configから認証情報を取得

import Combine
import Foundation

/// Upstash Redisベースのランキングリポジトリ
class RedisRankingRepository {
    // MARK: - Properties

    private let remoteConfigManager: RemoteConfigManager

    // MARK: - Initialization

    init(remoteConfigManager: RemoteConfigManager = .shared) {
        self.remoteConfigManager = remoteConfigManager
    }

    // MARK: - Public Methods

    /// ランキングデータを取得（Redisのみ）
    /// - Parameter limit: 取得件数
    /// - Returns: ユーザーIDの配列Publisher
    func fetchRanking(limit: Int) -> AnyPublisher<[String], Error> {
        return fetchFromRedis(limit: limit)
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    /// Upstash Redisから取得
    private func fetchFromRedis(limit: Int) -> AnyPublisher<[String], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            // Remote Configから認証情報を取得
            let redisURL = self.remoteConfigManager.redisURL
            let redisToken = self.remoteConfigManager.redisToken

            // 認証情報が未設定の場合はエラー
            guard !redisURL.isEmpty, !redisToken.isEmpty else {
                print("❌ Redis認証情報が未設定です。Remote Configを確認してください。")
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            // Upstash Redis REST API
            // ZREVRANGE ranking:maxConnections 0 (limit-1)
            let urlString = "\(redisURL)/zrevrange/ranking:maxConnections/0/\(limit - 1)"
            guard let url = URL(string: urlString) else {
                promise(.failure(RepositoryError.dataCorrupted))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(redisToken)", forHTTPHeaderField: "Authorization")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    promise(.failure(RepositoryError.dataCorrupted))
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    print("⚠️ Redis HTTPエラー: \(httpResponse.statusCode)")
                    promise(.failure(RedisError.httpError(httpResponse.statusCode)))
                    return
                }

                guard let data = data else {
                    promise(.failure(RepositoryError.dataCorrupted))
                    return
                }

                do {
                    // Upstash ResponseはJSON {"result": ["userId1", "userId2", ...]}
                    let response = try JSONDecoder().decode(UpstashResponse.self, from: data)
                    print("✅ Redis取得成功: \(response.result.count)件")
                    promise(.success(response.result))
                } catch {
                    promise(.failure(error))
                }
            }

            task.resume()
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

/// Upstash Redis REST APIレスポンス
struct UpstashResponse: Codable {
    let result: [String]
}

/// Redisエラー
enum RedisError: LocalizedError {
    case httpError(Int)  // HTTPエラー

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "Redis HTTPエラー: \(code)"
        }
    }
}

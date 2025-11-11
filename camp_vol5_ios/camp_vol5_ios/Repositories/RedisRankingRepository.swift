// Repositories/RedisRankingRepository.swift
// Cloud Functions経由でランキングデータ取得（オンメモリキャッシュ付き）
// Firebase FunctionsのgetRanking HTTPS Functionを呼び出し
// Upstashへの読み取り回数を削減（Functions側で5分間キャッシュ）

import Combine
import Foundation

/// Cloud Functions経由のランキングリポジトリ
class RedisRankingRepository {
    // MARK: - Properties

    private let functionURL =
        "https://asia-northeast1-heart-beat-23158.cloudfunctions.net/getRanking"

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// ランキングデータを取得（Cloud Functions経由）
    /// - Parameters:
    ///   - offset: 取得開始位置（0から始まる）
    ///   - limit: 取得件数
    /// - Returns: User全体の配列Publisher
    func fetchRanking(offset: Int, limit: Int) -> AnyPublisher<[User], Error> {
        return fetchFromCloudFunction(offset: offset, limit: limit)
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    /// Cloud Functionsから取得
    private func fetchFromCloudFunction(offset: Int, limit: Int) -> AnyPublisher<[User], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.serviceUnavailable))
                return
            }

            // Cloud Functions URL
            guard var urlComponents = URLComponents(string: self.functionURL) else {
                promise(.failure(RepositoryError.dataCorrupted))
                return
            }

            urlComponents.queryItems = [
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "limit", value: String(limit)),
            ]

            guard let url = urlComponents.url else {
                promise(.failure(RepositoryError.dataCorrupted))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

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
                    print("⚠️ Cloud Functions HTTPエラー: \(httpResponse.statusCode)")
                    promise(.failure(RankingError.httpError(httpResponse.statusCode)))
                    return
                }

                guard let data = data else {
                    promise(.failure(RepositoryError.dataCorrupted))
                    return
                }

                do {
                    // Cloud Functions Response
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let response = try decoder.decode(CloudFunctionResponse.self, from: data)

                    // RankingUserをUserに変換
                    let users = response.users.map { rankingUser in
                        User(
                            id: rankingUser.id,
                            name: rankingUser.name,
                            inviteCode: "",  // ランキングでは不要
                            allowQRRegistration: false,
                            createdAt: nil,
                            updatedAt: nil,
                            maxConnections: rankingUser.maxConnections,
                            maxConnectionsUpdatedAt: rankingUser.maxConnectionsUpdatedAt.map {
                                Date(timeIntervalSince1970: TimeInterval($0) / 1000)
                            }
                        )
                    }

                    if response.cached {
                        print(
                            "✅ Cloud Functions取得成功（キャッシュ）: \(users.count)件 (age: \(response.cacheAge)秒)"
                        )
                    } else {
                        print("✅ Cloud Functions取得成功（新規）: \(users.count)件")
                    }

                    promise(.success(users))
                } catch {
                    print("❌ レスポンスのパースエラー: \(error)")
                    promise(.failure(error))
                }
            }

            task.resume()
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

/// Cloud Functions getRankingレスポンス
struct CloudFunctionResponse: Codable {
    let users: [RankingUser]
    let cached: Bool
    let cacheAge: Int
}

/// ランキング用のUser情報
struct RankingUser: Codable {
    let id: String
    let name: String
    let maxConnections: Int
    let maxConnectionsUpdatedAt: Int?  // Unix timestamp (ms)
}

/// ランキングエラー
enum RankingError: LocalizedError {
    case httpError(Int)  // HTTPエラー

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "Cloud Functions HTTPエラー: \(code)"
        }
    }
}

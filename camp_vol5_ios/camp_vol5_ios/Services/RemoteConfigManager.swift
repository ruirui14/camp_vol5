// Services/RemoteConfigManager.swift
// Firebase Remote Configを使用した設定値管理
// Upstash Redis認証情報などの機密情報を安全に配信

import Combine
import FirebaseRemoteConfig
import Foundation

/// Remote Config管理クラス
/// アプリ起動時に設定値を取得し、全体で共有する
class RemoteConfigManager: ObservableObject {
    // MARK: - Singleton

    static let shared = RemoteConfigManager()

    // MARK: - Properties

    private let remoteConfig: RemoteConfig
    @Published private(set) var isConfigFetched = false

    // Redis認証情報
    @Published private(set) var redisURL: String = ""
    @Published private(set) var redisToken: String = ""

    // MARK: - Initialization

    private init() {
        remoteConfig = RemoteConfig.remoteConfig()

        // デフォルト値の設定
        let defaults: [String: NSObject] = [
            "REDIS_URL": "" as NSObject,
            "REDIS_TOKEN": "" as NSObject,
        ]
        remoteConfig.setDefaults(defaults)

        // 開発環境: キャッシュ無効化（本番環境では12時間推奨）
        #if DEBUG
            let settings = RemoteConfigSettings()
            settings.minimumFetchInterval = 0  // 開発時は即座に取得
            remoteConfig.configSettings = settings
        #endif
    }

    // MARK: - Public Methods

    /// Remote Configから設定値を取得
    /// アプリ起動時に呼び出す
    func fetchConfig() async throws {
        do {
            // リモートから最新の設定を取得
            let status = try await remoteConfig.fetch()
            print("📥 Remote Config fetch status: \(status)")

            // 取得した設定を有効化
            let activated = try await remoteConfig.activate()
            print("✅ Remote Config activated: \(activated)")

            // 設定値を読み込み
            loadConfigValues()

            await MainActor.run {
                isConfigFetched = true
            }
        } catch {
            print("❌ Remote Config fetch error: \(error.localizedDescription)")

            // エラー時はキャッシュされた値を使用
            loadConfigValues()

            await MainActor.run {
                isConfigFetched = true
            }

            throw error
        }
    }

    /// 同期的に設定値を取得（既にfetch済みの場合）
    func fetchConfigSync(completion: @escaping (Bool) -> Void) {
        remoteConfig.fetch { [weak self] _, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Remote Config fetch error: \(error.localizedDescription)")
                self.loadConfigValues()
                completion(false)
                return
            }

            self.remoteConfig.activate { [weak self] _, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Remote Config activate error: \(error.localizedDescription)")
                }

                self.loadConfigValues()
                self.isConfigFetched = true
                completion(true)
            }
        }
    }

    // MARK: - Private Methods

    /// 設定値を読み込んで@Publishedプロパティに反映
    private func loadConfigValues() {
        let fetchedRedisURL = remoteConfig.configValue(forKey: "REDIS_URL").stringValue ?? ""
        let fetchedRedisToken = remoteConfig.configValue(forKey: "REDIS_TOKEN").stringValue ?? ""

        DispatchQueue.main.async { [weak self] in
            self?.redisURL = fetchedRedisURL
            self?.redisToken = fetchedRedisToken

            print("🔧 Remote Config loaded:")
            print("  - REDIS_URL: \(fetchedRedisURL.isEmpty ? "(empty)" : "✓ set")")
            print("  - REDIS_TOKEN: \(fetchedRedisToken.isEmpty ? "(empty)" : "✓ set")")
        }
    }
}

// Services/YouTubeURLService.swift
// YouTube URL解析サービス - YouTube動画URLから動画IDを抽出
// 様々なYouTube URLフォーマット（youtu.be、youtube.com/watch、youtube.com/embedなど）に対応

import Foundation

/// YouTube URL解析サービスのプロトコル
protocol YouTubeURLServiceProtocol {
    /// YouTube URLから動画IDを抽出
    /// - Parameter urlString: YouTube URL文字列
    /// - Returns: 動画ID（11文字）。解析できない場合は空文字列
    func extractVideoID(from urlString: String) -> String
}

/// YouTube URL解析サービスの実装
final class YouTubeURLService: YouTubeURLServiceProtocol {
    // MARK: - Singleton

    static let shared = YouTubeURLService()

    private init() {}

    // MARK: - Public Methods

    /// YouTube URLから動画IDを抽出
    /// - Parameter urlString: YouTube URL文字列
    /// - Returns: 動画ID（11文字）。解析できない場合は空文字列
    ///
    /// サポートするフォーマット:
    /// - youtu.be/VIDEO_ID
    /// - youtube.com/watch?v=VIDEO_ID
    /// - youtube.com/embed/VIDEO_ID
    /// - VIDEO_ID（11文字の動画IDのみ）
    func extractVideoID(from urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)

        // 空の場合はデフォルト値を返す
        if trimmed.isEmpty {
            return ""
        }

        // 既に動画IDのみの場合（11文字）
        if trimmed.count == 11 && !trimmed.contains("/") && !trimmed.contains("?") {
            return trimmed
        }

        // youtu.be/XXXXXX 形式（?si= などのパラメータに対応）
        if let range = trimmed.range(of: "youtu.be/") {
            var id = String(trimmed[range.upperBound...])
            // ? や & があればそこまで切り取る
            if let questionMark = id.firstIndex(of: "?") {
                id = String(id[..<questionMark])
            }
            if let ampersand = id.firstIndex(of: "&") {
                id = String(id[..<ampersand])
            }
            return String(id.prefix(11))
        }

        // youtube.com/watch?v=XXXXXX 形式
        if let range = trimmed.range(of: "v=") {
            let id = String(trimmed[range.upperBound...])
            // &があればそこまで、なければ11文字
            if let ampersand = id.firstIndex(of: "&") {
                return String(id[..<ampersand])
            }
            return String(id.prefix(11))
        }

        // youtube.com/embed/XXXXXX 形式
        if let range = trimmed.range(of: "/embed/") {
            var id = String(trimmed[range.upperBound...])
            // ? や & があればそこまで切り取る
            if let questionMark = id.firstIndex(of: "?") {
                id = String(id[..<questionMark])
            }
            if let ampersand = id.firstIndex(of: "&") {
                id = String(id[..<ampersand])
            }
            return String(id.prefix(11))
        }

        return trimmed
    }
}

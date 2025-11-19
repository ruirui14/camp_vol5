// Views/Components/StreamWebViewWrapper.swift
// YouTubePlayerKitを使用したYouTube動画再生ラッパー
// YouTube動画をフルスクリーンで再生し、テキストオーバーレイをサポート
// YouTube IFrame Player APIの制限を回避し、安定した動画再生を実現
// YouTubeURLServiceを使用してURL解析を行い、MVVMアーキテクチャに準拠

import SwiftUI
import YouTubePlayerKit

struct StreamWebViewWrapper: View {
    // MARK: - Properties

    let urlString: String
    @State private var youtubePlayer: YouTubePlayer

    // MARK: - Dependencies

    private let youtubeURLService: YouTubeURLServiceProtocol

    // MARK: - Initialization

    init(
        urlString: String,
        youtubeURLService: YouTubeURLServiceProtocol = YouTubeURLService.shared
    ) {
        self.urlString = urlString
        self.youtubeURLService = youtubeURLService

        // YouTube URLから動画IDを抽出
        let videoID = youtubeURLService.extractVideoID(from: urlString)
        _youtubePlayer = State(
            initialValue: YouTubePlayer(
                source: .video(id: videoID),
                configuration: .init(
                    fullscreenMode: .system,
                    allowsInlineMediaPlayback: true
                )
            ))
    }

    // MARK: - Body

    var body: some View {
        YouTubePlayerView(youtubePlayer)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
            .onChange(of: urlString) { newValue in
                let videoID = youtubeURLService.extractVideoID(from: newValue)
                if !videoID.isEmpty {
                    // 新しい動画IDで YouTubePlayer を再作成
                    youtubePlayer = YouTubePlayer(
                        source: .video(id: videoID),
                        configuration: .init(
                            fullscreenMode: .system,
                            allowsInlineMediaPlayback: true
                        )
                    )
                }
            }
    }
}

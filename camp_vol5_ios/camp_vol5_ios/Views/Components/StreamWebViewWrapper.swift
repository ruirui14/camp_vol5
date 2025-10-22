// Views/Components/StreamWebViewWrapper.swift
// WKWebViewをSwiftUIで使用するためのラッパー
// 配信URLを表示するためのWebViewコンポーネント

import SwiftUI
import WebKit

struct StreamWebViewWrapper: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = true

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            return
        }

        // 現在のURLと異なる場合のみ読み込み
        if webView.url?.absoluteString != urlString {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

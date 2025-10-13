// Services/PerformanceMonitor.swift
// Firebase Performance Monitoringのヘルパークラス
// カスタムトレースを簡単に計測するためのユーティリティ

import FirebasePerformance
import Foundation

/// Firebase Performance Monitoring のラッパークラス
class PerformanceMonitor {
    /// シングルトンインスタンス
    static let shared = PerformanceMonitor()

    private init() {}

    // MARK: - Custom Traces

    /// 認証関連のトレース名
    enum AuthTrace: String {
        case signIn = "auth_sign_in"
        case signUp = "auth_sign_up"
        case signOut = "auth_sign_out"
        case googleSignIn = "auth_google_sign_in"
        case emailVerification = "auth_email_verification"
        case passwordReset = "auth_password_reset"
    }

    /// データ取得関連のトレース名
    enum DataTrace: String {
        case fetchUser = "data_fetch_user"
        case fetchHeartbeat = "data_fetch_heartbeat"
        case fetchFollowingUsers = "data_fetch_following_users"
        case createUser = "data_create_user"
        case updateUser = "data_update_user"
    }

    /// UI関連のトレース名
    enum UITrace: String {
        case screenLoad = "ui_screen_load"
        case imageLoad = "ui_image_load"
        case qrCodeGeneration = "ui_qr_code_generation"
    }

    // MARK: - Trace Management

    /// トレースを開始
    /// - Parameter name: トレース名
    /// - Returns: Traceオブジェクト（停止時に使用）
    func startTrace(_ name: String) -> Trace? {
        guard let trace = Performance.startTrace(name: name) else {
            print("⚠️ Failed to start trace: \(name)")
            return nil
        }
        print("🎯 Performance trace started: \(name)")
        return trace
    }

    /// トレースを開始（Enum版）
    func startTrace<T: RawRepresentable>(_ traceEnum: T) -> Trace? where T.RawValue == String {
        return startTrace(traceEnum.rawValue)
    }

    /// トレースを停止
    /// - Parameter trace: 停止するTraceオブジェクト
    func stopTrace(_ trace: Trace?) {
        guard let trace = trace else { return }
        trace.stop()
        print("🎯 Performance trace stopped: \(trace.name)")
    }

    /// トレースにカスタム属性を追加
    /// - Parameters:
    ///   - trace: Traceオブジェクト
    ///   - key: 属性キー
    ///   - value: 属性値
    func setAttribute(_ trace: Trace?, key: String, value: String) {
        trace?.setValue(value, forAttribute: key)
    }

    /// トレースにメトリクスを追加
    /// - Parameters:
    ///   - trace: Traceオブジェクト
    ///   - key: メトリクスキー
    ///   - value: メトリクス値
    func incrementMetric(_ trace: Trace?, key: String, by value: Int64 = 1) {
        trace?.incrementMetric(key, by: value)
    }

    // MARK: - Convenience Methods

    /// 処理を計測する（クロージャ版）
    /// - Parameters:
    ///   - name: トレース名
    ///   - block: 計測する処理
    func measure(_ name: String, block: () -> Void) {
        let trace = startTrace(name)
        block()
        stopTrace(trace)
    }

    /// 非同期処理を計測する
    /// - Parameters:
    ///   - name: トレース名
    ///   - block: 計測する非同期処理
    func measureAsync(_ name: String, block: @escaping (@escaping () -> Void) -> Void) {
        let trace = startTrace(name)
        block {
            self.stopTrace(trace)
        }
    }

    // MARK: - Network Monitoring

    /// HTTPメトリクスを記録（自動的に行われるが、手動でも可能）
    /// - Parameters:
    ///   - url: リクエストURL
    ///   - httpMethod: HTTPメソッド
    ///   - responseCode: レスポンスコード
    ///   - responseTime: レスポンス時間（ミリ秒）
    func recordHTTPMetric(
        url: URL,
        httpMethod: String,
        responseCode: Int,
        responseTime: TimeInterval
    ) {
        // HTTPMethodをStringから変換
        let method: HTTPMethod
        switch httpMethod.uppercased() {
        case "GET":
            method = .get
        case "POST":
            method = .post
        case "PUT":
            method = .put
        case "DELETE":
            method = .delete
        case "HEAD":
            method = .head
        case "PATCH":
            method = .patch
        case "OPTIONS":
            method = .options
        case "TRACE":
            method = .trace
        case "CONNECT":
            method = .connect
        default:
            method = .get
        }

        guard let metric = HTTPMetric(url: url, httpMethod: method)
        else {
            return
        }

        metric.responseCode = responseCode
        metric.responsePayloadSize = 0
        metric.start()

        // レスポンス時間を待機してから停止
        DispatchQueue.main.asyncAfter(deadline: .now() + responseTime / 1000) {
            metric.stop()
            print("🎯 HTTP metric recorded: \(url.absoluteString)")
        }
    }
}

// MARK: - Convenience Extensions

extension PerformanceMonitor {
    /// 認証トレースを計測
    func measureAuth(_ type: AuthTrace, block: () -> Void) {
        measure(type.rawValue, block: block)
    }

    /// データ取得トレースを計測
    func measureData(_ type: DataTrace, block: () -> Void) {
        measure(type.rawValue, block: block)
    }

    /// UIトレースを計測
    func measureUI(_ type: UITrace, block: () -> Void) {
        measure(type.rawValue, block: block)
    }
}

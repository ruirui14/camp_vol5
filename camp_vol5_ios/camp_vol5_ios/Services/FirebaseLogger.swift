// Services/FirebaseLogger.swift
// Firebase操作のログを管理するシンプルなロガー
// 本番環境では適切なログレベルとフィルタリングを実装

import Foundation
import os.log

class FirebaseLogger {
    static let shared = FirebaseLogger()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "Firebase")

    private init() {}

    func log(_ message: String) {
        logger.info("\(message)")
        print("🔥 [Firebase] \(message)")
    }

    func error(_ message: String) {
        logger.error("\(message)")
        print("❌ [Firebase Error] \(message)")
    }

    func warning(_ message: String) {
        logger.warning("\(message)")
        print("⚠️ [Firebase Warning] \(message)")
    }
}

// Views/Components/MessageBanner.swift
// 汎用メッセージバナーコンポーネント
// エラー、成功、情報など様々なメッセージタイプに対応した再利用可能なバナー

import SwiftUI

/// メッセージバナーコンポーネント
struct MessageBanner: View {
    // MARK: - Properties

    let message: String
    let type: MessageType
    let onDismiss: (() -> Void)?

    // MARK: - Initialization

    init(message: String, type: MessageType, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.type = type
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            Image(systemName: type.icon)
                .foregroundColor(type.primaryColor)
                .font(.title3)

            // メッセージテキスト
            Text(message)
                .font(.callout)
                .foregroundColor(.white)
                .fontWeight(.medium)
                .lineLimit(3)

            Spacer()

            // 閉じるボタン（onDismissが提供されている場合のみ表示）
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.title3)
                }
            }
        }
        .padding(16)
        .background(bannerBackground)
        .overlay(bannerBorder)
        .shadow(color: type.primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    // MARK: - Subviews

    /// バナーの背景
    private var bannerBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        type.primaryColor.opacity(0.4),
                        type.secondaryColor.opacity(0.3),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(.ultraThinMaterial.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// バナーのボーダー
    private var bannerBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(type.primaryColor.opacity(0.5), lineWidth: 1)
    }
}

// MARK: - MessageType

extension MessageBanner {
    /// メッセージのタイプを定義
    enum MessageType {
        case error
        case success
        case info
        case warning

        /// プライマリカラー
        var primaryColor: Color {
            switch self {
            case .error:
                return Color(hex: "FF6B6B")
            case .success:
                return Color(hex: "51CF66")
            case .info:
                return Color(hex: "4DABF7")
            case .warning:
                return Color(hex: "FFD43B")
            }
        }

        /// セカンダリカラー（グラデーション用）
        var secondaryColor: Color {
            switch self {
            case .error:
                return Color(hex: "EE5A6F")
            case .success:
                return Color(hex: "40C057")
            case .info:
                return Color(hex: "339AF0")
            case .warning:
                return Color(hex: "FCC419")
            }
        }

        /// アイコン
        var icon: String {
            switch self {
            case .error:
                return "exclamationmark.triangle.fill"
            case .success:
                return "checkmark.circle.fill"
            case .info:
                return "info.circle.fill"
            case .warning:
                return "exclamationmark.circle.fill"
            }
        }
    }
}

// MARK: - Convenience Initializers

extension MessageBanner {
    /// エラーメッセージバナーを作成
    static func error(
        message: String,
        onDismiss: (() -> Void)? = nil
    ) -> MessageBanner {
        MessageBanner(message: message, type: .error, onDismiss: onDismiss)
    }

    /// 成功メッセージバナーを作成
    static func success(
        message: String,
        onDismiss: (() -> Void)? = nil
    ) -> MessageBanner {
        MessageBanner(message: message, type: .success, onDismiss: onDismiss)
    }

    /// 情報メッセージバナーを作成
    static func info(
        message: String,
        onDismiss: (() -> Void)? = nil
    ) -> MessageBanner {
        MessageBanner(message: message, type: .info, onDismiss: onDismiss)
    }

    /// 警告メッセージバナーを作成
    static func warning(
        message: String,
        onDismiss: (() -> Void)? = nil
    ) -> MessageBanner {
        MessageBanner(message: message, type: .warning, onDismiss: onDismiss)
    }
}

// MARK: - Preview

#Preview("Error Message") {
    VStack(spacing: 20) {
        MessageBanner.error(message: "ユーザー名が見つかりませんでした") {
            print("Dismissed")
        }

        MessageBanner.success(message: "保存しました")

        MessageBanner.info(message: "新しいバージョンがあります")

        MessageBanner.warning(message: "ネットワーク接続が不安定です")
    }
    .padding()
}

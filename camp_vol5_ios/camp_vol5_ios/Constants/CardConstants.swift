// CardConstants.swift
// UserHeartbeatCardとListHeartBeatsViewの共通設定

import Foundation

struct CardConstants {
    // カードレイアウト設定
    static let cardHeight: CGFloat = 120
    static let cardHorizontalMargin: CGFloat = 12  // 左右のマージン
    static let cardVerticalSpacing: CGFloat = 10  // カード間のスペーシング
    static let cornerRadius: CGFloat = 20

    // ハート表示設定
    static let heartSize: CGFloat = 64
    static let heartRightMargin: CGFloat = 16  // 右端からの距離
    static let heartBottomMargin: CGFloat = 56  // 下端からの距離
    static let heartFontSize: CGFloat = 20  // ハート内のBPM文字サイズ

    // ユーザー名表示設定
    static let nameLeftMargin: CGFloat = 16  // 左端からの距離
    static let nameBottomMargin: CGFloat = 16  // 下端からの距離
    static let nameFontSizeBase: CGFloat = 32
    static let nameFontSizeRatio: CGFloat = 0.08  // 画面幅に対する比率

    // 計算プロパティ
    static func cardWidth(for screenWidth: CGFloat) -> CGFloat {
        return screenWidth - (cardHorizontalMargin * 2)
    }

    static func heartRightOffset(for cardWidth: CGFloat) -> CGFloat {
        return cardWidth - heartSize - heartRightMargin
    }

    static func nameFontSize(for cardWidth: CGFloat) -> CGFloat {
        return min(nameFontSizeBase, cardWidth * nameFontSizeRatio)
    }
}

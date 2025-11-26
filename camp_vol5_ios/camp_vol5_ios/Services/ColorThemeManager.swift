// ColorThemeManager.swift
// アプリ全体のカラーテーマを管理するサービス
// UserDefaultsを使ってユーザーが選択したカスタムカラーを永続化

import Combine
import SwiftUI

/// カラーテーマを管理するシングルトンサービス
/// UserDefaultsにカスタムカラーを保存し、アプリ全体で使用可能にする
@MainActor
class ColorThemeManager: ObservableObject {
    static let shared = ColorThemeManager()

    /// カラーがリセットされた時に送信される通知
    static let didResetToDefaultsNotification = Notification.Name(
        "ColorThemeManagerDidResetToDefaults")

    // MARK: - Published Properties

    /// メインカラー (Assets.xcassetsのデフォルト: #FABDC2)
    @Published var mainColor: Color

    /// アクセントカラー
    @Published var accentColor: Color

    /// ベースカラー
    @Published var baseColor: Color

    /// テキストカラー
    @Published var textColor: Color

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKey {
        static let mainColorHex = "colorTheme.main"
        static let accentColorHex = "colorTheme.accent"
        static let baseColorHex = "colorTheme.base"
        static let textColorHex = "colorTheme.text"
    }

    // MARK: - Default Colors (Assets.xcassetsから読み込んだデフォルト値)

    private let defaultMainColor = Color("main")
    private let defaultAccentColor = Color("accent")
    private let defaultBaseColor = Color("base")
    private let defaultTextColor = Color("text")

    // MARK: - Initialization

    private init() {
        // UserDefaultsから保存されたカラーを読み込み、なければデフォルト値を使用
        if let mainHex = UserDefaults.standard.string(forKey: UserDefaultsKey.mainColorHex) {
            self.mainColor = Color(hex: mainHex)
        } else {
            self.mainColor = defaultMainColor
        }

        if let accentHex = UserDefaults.standard.string(forKey: UserDefaultsKey.accentColorHex) {
            self.accentColor = Color(hex: accentHex)
        } else {
            self.accentColor = defaultAccentColor
        }

        if let baseHex = UserDefaults.standard.string(forKey: UserDefaultsKey.baseColorHex) {
            self.baseColor = Color(hex: baseHex)
        } else {
            self.baseColor = defaultBaseColor
        }

        if let textHex = UserDefaults.standard.string(forKey: UserDefaultsKey.textColorHex) {
            self.textColor = Color(hex: textHex)
        } else {
            self.textColor = defaultTextColor
        }
    }

    // MARK: - Public Methods

    /// メインカラーを更新してUserDefaultsに保存
    /// アクセントカラーは自動的にメインカラーから派生した色を設定
    func updateMainColor(_ color: Color) {
        mainColor = color
        // アクセントカラーはメインカラーを少し暗くした色を自動生成
        accentColor = color.adjustBrightness(by: -0.1)

        UserDefaults.standard.set(color.toHex(), forKey: UserDefaultsKey.mainColorHex)
        if let accentHex = accentColor.toHex() {
            UserDefaults.standard.set(accentHex, forKey: UserDefaultsKey.accentColorHex)
        }
    }

    /// アクセントカラーを更新してUserDefaultsに保存
    func updateAccentColor(_ color: Color) {
        accentColor = color
        UserDefaults.standard.set(color.toHex(), forKey: UserDefaultsKey.accentColorHex)
    }

    /// ベースカラーを更新してUserDefaultsに保存
    func updateBaseColor(_ color: Color) {
        baseColor = color
        UserDefaults.standard.set(color.toHex(), forKey: UserDefaultsKey.baseColorHex)
    }

    /// テキストカラーを更新してUserDefaultsに保存
    func updateTextColor(_ color: Color) {
        textColor = color
        UserDefaults.standard.set(color.toHex(), forKey: UserDefaultsKey.textColorHex)
    }

    /// すべてのカラーをデフォルト値にリセット
    /// UserDefaultsから削除した後、Assets.xcassetsから色を読み込む
    func resetToDefaults() {
        // UserDefaultsから削除
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.mainColorHex)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.accentColorHex)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.baseColorHex)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.textColorHex)

        // 一度クリアカラーに設定してから、デフォルトカラーに戻すことで変更検知を確実にする
        mainColor = .clear
        accentColor = .clear
        baseColor = .clear
        textColor = .clear

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Assets.xcassetsから直接デフォルトカラーを読み込み
            // updateMainColor() などは使わない（accentColorが自動生成されてしまうため）
            // update-Colorを使わなくても、UserDefaultsが空の状態で初期化されるため、デフォルト色が自動で設定される
            self.mainColor = Color("main")
            self.accentColor = Color("accent")
            self.baseColor = Color("base")
            self.textColor = Color("text")

            // ColorPickerなどのUIコンポーネントに通知
            NotificationCenter.default.post(
                name: ColorThemeManager.didResetToDefaultsNotification, object: nil)
        }
    }

    /// メインカラーに応じた適切なアイコン色を返す
    /// 透明度が低い場合や明るい色の場合は、コントラストを確保した色を返す
    var iconColor: Color {
        let opacity = mainColor.opacity()
        let isLight = mainColor.isLightColor()

        // 透明度が0.5未満の場合は、背景が透けて見えにくいので濃い色を使う
        if opacity < 0.2 {
            return .gray
        }

        // 明るい色(白やパステルカラー)の場合は暗い色を使う
        if isLight {
            // 白に近い場合はグレー、その他の明るい色は元の色を暗くする
            if mainColor.isWhite() {
                return .gray
            } else {
                return mainColor.adjustBrightness(by: -0.2)
            }
        }

        // 暗い色の場合はそのまま使う
        return mainColor
    }
}

// MARK: - Color Extension for Hex Conversion

extension Color {
    /// ColorをHex文字列に変換 (例: "#FABDC2" または "#FABDC2FF" (透明度付き))
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)

        // アルファ値を取得(RGB + Alphaの4要素の場合は最後の要素)
        if components.count >= 4 {
            let alpha = Int(components[3] * 255)
            return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
        }

        // アルファ値がない場合は不透明として保存
        return String(format: "#%02X%02X%02XFF", red, green, blue)
    }

    /// 明度を調整した色を返す
    /// - Parameter amount: 調整量 (-1.0 ~ 1.0)。負の値で暗く、正の値で明るく
    func adjustBrightness(by amount: Double) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // 明度を調整 (0.0 ~ 1.0の範囲に制限)
        let newBrightness = max(0, min(1, brightness + CGFloat(amount)))

        return Color(
            hue: Double(hue),
            saturation: Double(saturation),
            brightness: Double(newBrightness),
            opacity: Double(alpha)
        )
    }

    /// 色の明度に基づいて、コントラストの高い色(黒または白)を返す
    /// 明るい色の場合は黒、暗い色の場合は白を返す
    func contrastingColor() -> Color {
        guard let components = UIColor(self).cgColor.components else {
            return .primary
        }

        // RGB値を取得
        let red = components[0]
        let green = components[1]
        let blue = components[2]

        // 相対輝度を計算 (ITU-R BT.709の係数を使用)
        // 人間の目は緑に最も敏感、次に赤、青の順
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        // 輝度が0.5以上の場合は明るい色とみなし、黒を返す
        // それ以外は暗い色とみなし、白を返す
        return luminance > 0.5 ? .black : .white
    }

    /// 色が白またはほぼ白かどうかを判定
    /// RGB値が全て0.95以上の場合に白とみなす
    func isWhite() -> Bool {
        guard let components = UIColor(self).cgColor.components else {
            return false
        }

        // RGB値を取得
        let red = components[0]
        let green = components[1]
        let blue = components[2]

        // RGB値が全て0.95以上の場合に白とみなす（少しの誤差を許容）
        return red > 0.95 && green > 0.95 && blue > 0.95
    }

    /// 色の透明度(alpha値)を取得
    /// 0.0(完全に透明) ~ 1.0(完全に不透明)
    func opacity() -> CGFloat {
        guard let components = UIColor(self).cgColor.components else {
            return 1.0
        }

        // アルファ値を取得(RGB + Alphaの4要素の場合は最後の要素)
        if components.count >= 4 {
            return components[3]
        }

        // アルファ値がない場合は不透明とみなす
        return 1.0
    }

    /// 色が明るいかどうかを判定
    /// 相対輝度が0.6以上の場合に明るいとみなす
    func isLightColor() -> Bool {
        guard let components = UIColor(self).cgColor.components else {
            return false
        }

        // RGB値を取得
        let red = components[0]
        let green = components[1]
        let blue = components[2]

        // 相対輝度を計算 (ITU-R BT.709の係数を使用)
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        // 輝度が0.6以上の場合に明るい色とみなす(contrastingColor()より厳しめの閾値)
        return luminance > 0.6
    }
}

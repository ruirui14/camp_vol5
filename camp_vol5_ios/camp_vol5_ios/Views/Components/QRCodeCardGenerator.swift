import CoreImage
import UIKit

/// QRコードカードを生成するジェネレータークラス
/// - 背景グラデーション
/// - ハートの装飾
/// - 白いカード
/// - QRコード + 中央アイコン
/// - ユーザー名
class QRCodeCardGenerator {
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    /// カスタムデザインのQRコード画像を生成
    /// - Parameters:
    ///   - inviteCode: 招待コード（QRコードにエンコードする文字列）
    ///   - userName: ユーザー名（カード下部に表示）
    /// - Returns: 生成されたQRコードカード画像
    func generateStyledQRCode(from inviteCode: String, userName: String?) -> UIImage {
        // 基本的なQRコードを生成
        filter.message = Data(inviteCode.utf8)
        filter.correctionLevel = "H"  // 高い誤り訂正レベルで中央にアイコンを配置可能に

        guard let outputImage = filter.outputImage else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }

        // QRコードを高解像度にスケーリング
        let transform = CGAffineTransform(scaleX: 20, y: 20)
        let scaledQRImage = outputImage.transformed(by: transform)

        guard let qrCGImage = context.createCGImage(scaledQRImage, from: scaledQRImage.extent)
        else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }

        let qrUIImage = UIImage(cgImage: qrCGImage)

        // キャンバスサイズを計算（QR + 余白）
        let qrSize: CGFloat = qrUIImage.size.width
        let verticalPadding: CGFloat = 580  // ピンク背景の上下に追加の余白
        let horizontalPadding: CGFloat = 120  // ピンク背景の左右に追加の余白
        let canvasSize = CGSize(
            width: qrSize + horizontalPadding,
            height: qrSize + verticalPadding
        )

        // 内部の余白を計算
        let innerHorizontalPadding = horizontalPadding / 2
        let textAreaHeight: CGFloat = 60

        // 描画開始
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }

        // 背景グラデーションを描画
        drawBackground(in: ctx, canvasSize: canvasSize)

        // ハートの装飾を描画
        drawHeartDecorations(in: ctx, canvasSize: canvasSize)

        // 白い背景のカードを描画（QRコードとテキストエリアを含む高さ）
        let cardHeight = qrSize + textAreaHeight + 40  // 40はQRとテキスト間の余白
        let cardRect = CGRect(
            x: innerHorizontalPadding / 2,
            y: (canvasSize.height - cardHeight) / 2,  // 上下中央に配置
            width: canvasSize.width - innerHorizontalPadding,
            height: cardHeight
        )
        ctx.setFillColor(UIColor.white.cgColor)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 20)
        cardPath.fill()

        // QRコードを描画（カード内の上部に配置）
        let qrRect = CGRect(
            x: innerHorizontalPadding,
            y: cardRect.minY + 20,  // カードの上端から20pxの余白
            width: qrSize,
            height: qrSize
        )
        qrUIImage.draw(in: qrRect)

        // 中央にkyouaiアイコンを配置
        if let kyouaiIcon = UIImage(named: "kyouai") {
            let iconSize: CGFloat = qrSize * 0.25
            let iconRect = CGRect(
                x: innerHorizontalPadding + (qrSize - iconSize) / 2,
                y: qrRect.minY + (qrSize - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            kyouaiIcon.draw(in: iconRect)
        }

        // ユーザー名の表示
        if let name = userName {
            let nameText = "❤️ \(name)" as NSString
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 45, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            let nameSize = nameText.size(withAttributes: nameAttributes)
            let nameRect = CGRect(
                x: (canvasSize.width - nameSize.width) / 2,
                y: qrRect.maxY,
                width: nameSize.width,
                height: nameSize.height
            )
            nameText.draw(in: nameRect, withAttributes: nameAttributes)
        }

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage ?? UIImage(systemName: "xmark.circle") ?? UIImage()
    }

    /// 背景グラデーションを描画
    /// linear-gradient(171.11deg, #FFC6CB 4.73%, #FEB9BF 65.75%, #F9939E 111.39%)
    private func drawBackground(in context: CGContext, canvasSize: CGSize) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(red: 1.0, green: 198.0 / 255.0, blue: 203.0 / 255.0, alpha: 1.0).cgColor,  // #FFC6CB
            UIColor(red: 254.0 / 255.0, green: 185.0 / 255.0, blue: 191.0 / 255.0, alpha: 1.0)
                .cgColor,  // #FEB9BF
            UIColor(red: 249.0 / 255.0, green: 147.0 / 255.0, blue: 158.0 / 255.0, alpha: 1.0)
                .cgColor  // #F9939E
        ]
        let locations: [CGFloat] = [0.0473, 0.6575, 1.0]
        let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: locations
        )!

        // 171.11度の角度でグラデーションを適用
        let angle = 171.11 * CGFloat.pi / 180
        let dx = sin(angle)
        let dy = -cos(angle)

        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        let diagonal = sqrt(
            canvasSize.width * canvasSize.width + canvasSize.height * canvasSize.height)

        let startX = centerX - dx * diagonal / 2
        let startY = centerY - dy * diagonal / 2
        let endX = centerX + dx * diagonal / 2
        let endY = centerY + dy * diagonal / 2

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: startX, y: startY),
            end: CGPoint(x: endX, y: endY),
            options: []
        )
    }

    /// ハートの装飾を描画
    private func drawHeartDecorations(in context: CGContext, canvasSize: CGSize) {
        // (位置(x: 横, y: 縦), サイズ, 角度(度))
        let hearts: [(CGPoint, CGFloat, CGFloat)] = [
            // 上部のハート
            (CGPoint(x: 60, y: 160), 55, -13),  // 左上（左に15度傾ける）
            (CGPoint(x: 120, y: 190), 35, 8),  // 右に20度傾ける

            // 下部のハート（右端から固定距離）
            (CGPoint(x: canvasSize.width - 160, y: canvasSize.height - 150), 35, -15),  // 左下
            (CGPoint(x: canvasSize.width - 110, y: canvasSize.height - 190), 55, +8),  // 中央
            (CGPoint(x: canvasSize.width - 60, y: canvasSize.height - 150), 40, +8)  // 右下
        ]

        for (center, size, angle) in hearts {
            drawHeart(in: context, center: center, size: size, angle: angle)
        }
    }

    /// 単一のハートを描画
    /// - Parameters:
    ///   - context: 描画コンテキスト
    ///   - center: ハートの中心座標
    ///   - size: ハートのサイズ
    ///   - angle: 回転角度（度）。正の値で時計回り、負の値で反時計回り
    private func drawHeart(
        in context: CGContext, center: CGPoint, size: CGFloat, angle: CGFloat = 0
    ) {
        context.saveGState()

        // 角度を適用（度をラジアンに変換）
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: angle * .pi / 180)
        context.translateBy(x: -center.x, y: -center.y)

        let heartPath = UIBezierPath()
        let topY = center.y - size / 4
        let bottomY = center.y + size / 2

        heartPath.move(to: CGPoint(x: center.x, y: bottomY))

        heartPath.addCurve(
            to: CGPoint(x: center.x - size / 2, y: topY),
            controlPoint1: CGPoint(x: center.x - size / 2, y: center.y + size / 4),
            controlPoint2: CGPoint(x: center.x - size / 2, y: topY + size / 8)
        )

        heartPath.addArc(
            withCenter: CGPoint(x: center.x - size / 4, y: topY),
            radius: size / 4,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )

        heartPath.addArc(
            withCenter: CGPoint(x: center.x + size / 4, y: topY),
            radius: size / 4,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )

        heartPath.addCurve(
            to: CGPoint(x: center.x, y: bottomY),
            controlPoint1: CGPoint(x: center.x + size / 2, y: topY + size / 8),
            controlPoint2: CGPoint(x: center.x + size / 2, y: center.y + size / 4)
        )

        context.setFillColor(UIColor(red: 1.0, green: 0.45, blue: 0.55, alpha: 0.6).cgColor)
        heartPath.fill()

        context.restoreGState()
    }
}

// MARK: - Preview

#if DEBUG
    import SwiftUI

    /// QRコードカードのプレビュー用ビュー
    /// デバッグ時にXcode Canvasで確認するためのコンポーネント
    struct QRCodeCardPreview: View {
        let qrCodeImage: UIImage

        var body: some View {
            VStack(spacing: 0) {
                Image(uiImage: qrCodeImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }
            .background(Color.black)
        }
    }

    struct QRCodeCardGenerator_Previews: PreviewProvider {
        static var previews: some View {
            // QRCodeCardGeneratorを直接使用してプレビュー
            let generator = QRCodeCardGenerator()
            let qrCardImage = generator.generateStyledQRCode(
                from: "PREVIEW-CODE-12345",
                userName: "狂愛ちゃん"
            )

            return Group {
                // 実際のサイズ感を確認できるプレビュー
                QRCodeCardPreview(qrCodeImage: qrCardImage)
                    .previewDisplayName("QRコードカード")
                    .previewLayout(.sizeThatFits)

                // デバイス上での表示を確認
                ScrollView {
                    QRCodeCardPreview(qrCodeImage: qrCardImage)
                        .padding()
                }
                .previewDisplayName("QRコードカード（デバイス）")
                .previewDevice("iPhone 16")
            }
        }
    }
#endif

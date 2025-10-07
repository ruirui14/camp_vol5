import Combine
import CoreImage.CIFilterBuiltins
import Foundation
import Photos
import SwiftUI

class QRCodeShareViewModel: ObservableObject {
    @Published var inviteCode: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var qrCodeImage: UIImage?
    @Published var currentBPM: Int?
    @Published var userName: String?

    @Published var showingSaveAlert = false
    @Published var saveAlertTitle = ""
    @Published var saveAlertMessage = ""
    @Published var showingPermissionAlert = false

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    private var authenticationManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        setupBindings()

        // 初期化時に既存のinviteCodeがある場合は設定
        if let currentUser = authenticationManager.currentUser,
            !currentUser.inviteCode.isEmpty
        {
            inviteCode = currentUser.inviteCode
            userName = currentUser.name
            qrCodeImage = generateStyledQRCode(from: currentUser.inviteCode)
        } else if authenticationManager.isAuthenticated {
            authenticationManager.refreshCurrentUser()

            // 少し待ってからinviteCodeがない場合は新規生成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let currentUser = self.authenticationManager.currentUser,
                    currentUser.inviteCode.isEmpty
                {
                    self.generateNewInviteCode()
                }
            }
        }
    }

    func updateAuthenticationManager(_ authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        cancellables.removeAll()
        setupBindings()

        // 既存のinviteCodeがある場合は設定
        if let currentUser = authenticationManager.currentUser,
            !currentUser.inviteCode.isEmpty
        {
            inviteCode = currentUser.inviteCode
            userName = currentUser.name
            qrCodeImage = generateStyledQRCode(from: currentUser.inviteCode)
        } else if authenticationManager.isAuthenticated {
            authenticationManager.refreshCurrentUser()

            // 少し待ってからinviteCodeがない場合は新規生成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let currentUser = self.authenticationManager.currentUser,
                    currentUser.inviteCode.isEmpty
                {
                    self.generateNewInviteCode()
                }
            }
        }
    }

    private func setupBindings() {
        guard authenticationManager.isAuthenticated else {
            return
        }

        // ユーザー名の監視
        authenticationManager.$currentUser
            .compactMap { $0?.name }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                self?.userName = name
                // ユーザー名が変わったらQRコードを再生成
                if let inviteCode = self?.inviteCode {
                    self?.qrCodeImage = self?.generateStyledQRCode(from: inviteCode)
                }
            }
            .store(in: &cancellables)

        // inviteCodeの監視
        authenticationManager.$currentUser
            .compactMap { $0?.inviteCode }
            .filter { !$0.isEmpty }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inviteCode in
                // ローディング中または既に同じinviteCodeの場合は更新をスキップ
                guard let self = self,
                    !self.isLoading,
                    self.inviteCode != inviteCode
                else {
                    return
                }

                self.inviteCode = inviteCode
                self.qrCodeImage = self.generateStyledQRCode(from: inviteCode)
            }
            .store(in: &cancellables)

        // 心拍数の監視
        if let userId = authenticationManager.currentUserId {
            HeartbeatService.shared.subscribeToHeartbeat(userId: userId)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] heartbeat in
                    self?.currentBPM = heartbeat?.bpm
                    // 心拍数が変わったらQRコードを再生成
                    if let inviteCode = self?.inviteCode {
                        self?.qrCodeImage = self?.generateStyledQRCode(from: inviteCode)
                    }
                }
                .store(in: &cancellables)
        }
    }

    func generateNewInviteCode() {
        guard authenticationManager.currentUserId != nil else {
            errorMessage = "User not logged in"
            return
        }

        isLoading = true
        errorMessage = nil

        guard let currentUser = authenticationManager.currentUser else {
            errorMessage = "User not logged in"
            isLoading = false
            return
        }

        UserService.shared.generateNewInviteCode(for: currentUser)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] newInviteCode in
                    // 直接inviteCodeとQRコードを更新
                    self?.inviteCode = newInviteCode
                    self?.qrCodeImage = self?.generateStyledQRCode(from: newInviteCode)

                    // 循環参照を防ぐため、authenticationManager.refreshCurrentUser()は呼ばない
                    // UserServiceがFirebaseを更新するので、setupBindingsで自動的に反映される
                }
            )
            .store(in: &cancellables)
    }

    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgimg = context.createCGImage(
                scaledImage,
                from: scaledImage.extent
            ) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }

    /// カスタムデザインのQRコード画像を生成
    /// - 中央にkyouaiアイコンを配置
    /// - 下部に心拍数とユーザー名を表示
    /// - ピンクのグラデーション背景にハートの装飾
    func generateStyledQRCode(from string: String) -> UIImage {
        // 基本的なQRコードを生成
        filter.message = Data(string.utf8)
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
        let textAreaHeight: CGFloat = 100

        // 描画開始
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }

        // 背景グラデーション（ピンク系）
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let pinkStart = UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0).cgColor
        let pinkEnd = UIColor(red: 1.0, green: 0.9, blue: 0.95, alpha: 1.0).cgColor
        let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [pinkStart, pinkEnd] as CFArray,
            locations: [0.0, 1.0]
        )!

        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: canvasSize.width, y: canvasSize.height),
            options: []
        )

        // ハートの装飾を描画（背景に複数配置）
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

        // テキストエリア（心拍数とユーザー名）
        let textY = qrRect.maxY + 20

        // 心拍数の表示
        if let bpm = currentBPM {
            let heartText = "❤️ \(bpm)bpm" as NSString
            let heartAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor(red: 1.0, green: 0.4, blue: 0.5, alpha: 1.0),
            ]
            let heartSize = heartText.size(withAttributes: heartAttributes)
            let heartRect = CGRect(
                x: (canvasSize.width - heartSize.width) / 2,
                y: textY,
                width: heartSize.width,
                height: heartSize.height
            )
            heartText.draw(in: heartRect, withAttributes: heartAttributes)
        }

        // ユーザー名の表示
        if let name = userName {
            let nameText = "❤️ \(name)" as NSString
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: UIColor.darkGray,
            ]
            let nameSize = nameText.size(withAttributes: nameAttributes)
            let nameRect = CGRect(
                x: (canvasSize.width - nameSize.width) / 2,
                y: textY + 40,
                width: nameSize.width,
                height: nameSize.height
            )
            nameText.draw(in: nameRect, withAttributes: nameAttributes)
        }

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage ?? UIImage(systemName: "xmark.circle") ?? UIImage()
    }

    /// ハートの装飾を描画
    private func drawHeartDecorations(in context: CGContext, canvasSize: CGSize) {
        let hearts: [(CGPoint, CGFloat)] = [
            (CGPoint(x: 50, y: 50), 30),
            (CGPoint(x: canvasSize.width - 60, y: 80), 25),
            (CGPoint(x: 70, y: canvasSize.height - 100), 35),
            (CGPoint(x: canvasSize.width - 70, y: canvasSize.height - 120), 28),
            (CGPoint(x: canvasSize.width / 2 - 100, y: 100), 22),
            (CGPoint(x: canvasSize.width / 2 + 100, y: canvasSize.height - 80), 26),
        ]

        for (center, size) in hearts {
            drawHeart(in: context, center: center, size: size)
        }
    }

    /// 単一のハートを描画
    private func drawHeart(in context: CGContext, center: CGPoint, size: CGFloat) {
        context.saveGState()

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

        context.setFillColor(UIColor(red: 1.0, green: 0.6, blue: 0.7, alpha: 0.3).cgColor)
        heartPath.fill()

        context.restoreGState()
    }

    func saveQRCodeToPhotos() {
        guard let qrImage = qrCodeImage else {
            return
        }

        checkPhotoLibraryPermission { [weak self] authorized in
            if authorized {
                self?.saveImageToPhotoLibrary(qrImage)
            } else {
                DispatchQueue.main.async {
                    self?.showingPermissionAlert = true
                }
            }
        }
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.saveAlertTitle = "保存エラー"
                    self?.saveAlertMessage = error.localizedDescription
                } else if success {
                    self?.saveAlertTitle = "保存完了"
                    self?.saveAlertMessage = "QRコードが写真に保存されました"
                } else {
                    self?.saveAlertTitle = "保存エラー"
                    self?.saveAlertMessage = "QRコードの保存に失敗しました"
                }
                self?.showingSaveAlert = true
            }
        }
    }

    private func generateHighResolutionQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 20, y: 20)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let uiImage = UIImage(cgImage: cgimg)

                let padding: CGFloat = 50
                let size = CGSize(
                    width: uiImage.size.width + (padding * 2),
                    height: uiImage.size.height + (padding * 2)
                )

                UIGraphicsBeginImageContextWithOptions(size, false, 0)

                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let colors = [
                    UIColor(Color.main).cgColor,
                    UIColor(Color.accent).cgColor,
                ]
                let gradient = CGGradient(
                    colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0]
                )!

                let context = UIGraphicsGetCurrentContext()!
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )

                let qrDrawRect = CGRect(
                    x: (size.width - uiImage.size.width) / 2,
                    y: (size.height - uiImage.size.height) / 2,
                    width: uiImage.size.width,
                    height: uiImage.size.height
                )
                uiImage.draw(in: qrDrawRect)

                let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                return finalImage ?? uiImage
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }

    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized,
            .limited:
            completion(true)
        case .denied,
            .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    let granted = newStatus == .authorized || newStatus == .limited
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }

}

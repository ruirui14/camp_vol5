import Combine
import CoreImage.CIFilterBuiltins
import Foundation
import Photos
import SwiftUI

class QRCodeShareViewModel: BaseViewModel {
    @Published var inviteCode: String?
    @Published var qrCodeImage: UIImage?
    @Published var currentBPM: Int?
    @Published var userName: String?
    @Published var allowQRRegistration: Bool = true

    @Published var showingSaveAlert = false
    @Published var saveAlertTitle = ""
    @Published var saveAlertMessage = ""
    @Published var showingPermissionAlert = false

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    private let cardGenerator = QRCodeCardGenerator()

    private var authenticationManager: AuthenticationManager

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        super.init()
        setupBindings()
        print("🔥 QRCodeShareViewModel init started")

        // 初期化時に既存のinviteCodeがある場合は設定
        if let currentUser = authenticationManager.currentUser,
            !currentUser.inviteCode.isEmpty
        {
            inviteCode = currentUser.inviteCode
            userName = currentUser.name
            allowQRRegistration = currentUser.allowQRRegistration
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

        // allowQRRegistrationの監視
        authenticationManager.$currentUser
            .compactMap { $0?.allowQRRegistration }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] allowQRRegistration in
                self?.allowQRRegistration = allowQRRegistration
            }
            .store(in: &cancellables)

        // 心拍数の監視
        if let userId = authenticationManager.currentUserId {
            HeartbeatService.shared.subscribeToHeartbeat(userId: userId)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] heartbeat in
                    self?.currentBPM = heartbeat?.bpm
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

    // QR登録許可設定を切り替え
    func toggleQRRegistration() {
        guard authenticationManager.currentUserId != nil else {
            errorMessage = "認証が必要です"
            return
        }

        // 現在のallowQRRegistrationの値を使用
        let newValue = allowQRRegistration
        isLoading = true

        guard let currentUser = authenticationManager.currentUser else {
            errorMessage = "Current user not found"
            isLoading = false
            return
        }

        UserService.shared.updateQRRegistrationSetting(for: currentUser, allow: newValue)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case let .failure(error) = completion {
                        // エラーの場合、トグルを元に戻す
                        self?.allowQRRegistration = !newValue
                        self?.errorMessage = error.localizedDescription
                    } else {
                        // AuthServiceの現在のユーザー情報を更新
                        self?.authenticationManager.refreshCurrentUser()
                    }
                },
                receiveValue: { _ in }
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
    /// QRCodeCardGeneratorを使用してQRコードカード全体を生成
    func generateStyledQRCode(from string: String) -> UIImage {
        return cardGenerator.generateStyledQRCode(from: string, userName: userName)
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

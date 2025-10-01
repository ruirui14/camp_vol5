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
            qrCodeImage = generateQRCode(from: currentUser.inviteCode)
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
            qrCodeImage = generateQRCode(from: currentUser.inviteCode)
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
                self.qrCodeImage = self.generateQRCode(from: inviteCode)
            }
            .store(in: &cancellables)
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
                    self?.qrCodeImage = self?.generateQRCode(from: newInviteCode)

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

    func saveQRCodeToPhotos() {
        guard let inviteCode = inviteCode else {
            return
        }

        let qrImage = generateHighResolutionQRCode(from: inviteCode)

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

import CoreImage.CIFilterBuiltins
import Photos
import SwiftUI

struct QRCodeShareView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: QRCodeShareViewModel
    @Environment(\.presentationMode) var presentationMode

    // QRコード保存関連
    @State private var showingSaveAlert = false
    @State private var saveAlertTitle = ""
    @State private var saveAlertMessage = ""
    @State private var showingPermissionAlert = false

    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    init() {
        _viewModel = StateObject(
            wrappedValue: QRCodeShareViewModel(
                authenticationManager: AuthenticationManager()
            ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if authenticationManager.isGoogleAuthenticated {
                    authenticatedContent
                } else {
                    guestUserContent
                }
            }
            .padding()
            .navigationTitle("QRコード共有")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.main, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                viewModel.updateAuthenticationManager(authenticationManager)
                // Google認証済みの場合、ユーザー情報を読み込み
                if authenticationManager.isGoogleAuthenticated {
                    authenticationManager.refreshCurrentUser()
                }
            }
            .alert("保存完了", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveAlertMessage)
            }
            .alert("写真へのアクセス許可", isPresented: $showingPermissionAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("QRコードを保存するには、設定で写真へのアクセスを許可してください。")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    // MARK: - View Components

    private var authenticatedContent: some View {
        VStack(spacing: 30) {
            if let inviteCode = viewModel.inviteCode {
                VStack(spacing: 20) {
                    //QRコード
                    Image(uiImage: generateQRCode(from: inviteCode))
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(
                            color: .gray.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )

                    // ボタンたち

                    HStack(spacing: 20) {
                        // 更新
                        Button(action: {
                            viewModel.generateNewInviteCode()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        // リンク
                        Button(action: {
                            UIPasteboard.general.string = inviteCode
                        }) {
                            HStack {
                                Image(systemName: "link")
                            }
                        }

                        // シェア
                        ShareLink(item: URL(string: "https://developer.apple.com/xcode/swiftui/")!)
                        {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                        }

                        // 保存
                        Button(action: {
                            saveQRCodeToPhotos()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.to.line")
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("招待コードを読み込み中...")
                        .foregroundColor(.secondary)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.callout)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()
        }
    }

    private var guestUserContent: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "qrcode")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 16) {
                Text("QRコード共有機能")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Google認証を行うと、あなた専用のQRコードが生成され、友達があなたを簡単にフォローできるようになります")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                authenticationManager.signInWithGoogle()
            }) {
                HStack {
                    if authenticationManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "globe")
                    }
                    Text(authenticationManager.isLoading ? "認証中..." : "Googleで認証")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authenticationManager.isLoading)

            if let errorMessage = authenticationManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .onTapGesture {
                        authenticationManager.clearError()
                    }
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

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

    // MARK: - Save to Photos

    private func saveQRCodeToPhotos() {
        guard let inviteCode = viewModel.inviteCode else { return }

        // 高解像度のQRコードを生成
        let qrImage = generateHighResolutionQRCode(from: inviteCode)

        // 写真ライブラリへのアクセス権限を確認
        checkPhotoLibraryPermission { authorized in
            if authorized {
                // 権限がある場合は保存
                saveImageToPhotoLibrary(qrImage)
            } else {
                // 権限がない場合はアラートを表示
                showingPermissionAlert = true
            }
        }
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        // PHPhotoLibraryを使用して保存
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.saveAlertTitle = "保存エラー"
                    self.saveAlertMessage = error.localizedDescription
                } else if success {
                    self.saveAlertTitle = "保存完了"
                    self.saveAlertMessage = "QRコードが写真に保存されました"
                } else {
                    self.saveAlertTitle = "保存エラー"
                    self.saveAlertMessage = "QRコードの保存に失敗しました"
                }
                self.showingSaveAlert = true
            }
        }
    }

    private func generateHighResolutionQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            // より高解像度で生成（20倍）
            let transform = CGAffineTransform(scaleX: 20, y: 20)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                let uiImage = UIImage(cgImage: cgimg)

                // 背景サイズを計算（QRコードのみ）
                let padding: CGFloat = 50
                let size = CGSize(
                    width: uiImage.size.width + (padding * 2),
                    height: uiImage.size.height + (padding * 2)
                )

                UIGraphicsBeginImageContextWithOptions(size, false, 0)

                // グラデーション背景を描画
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let colors = [
                    UIColor(Color.main).cgColor,
                    UIColor(Color.accent).cgColor,
                ]
                let gradient = CGGradient(
                    colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!

                let context = UIGraphicsGetCurrentContext()!
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )

                // QRコードを中央に描画
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
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }
}

struct QRCodeShareView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 未認証状態（デフォルト）
            QRCodeShareView()
                .environmentObject(AuthenticationManager())
                .previewDisplayName("未認証状態")

            // 認証済み状態をシミュレーション
            QRCodeShareView()
                .environmentObject(
                    {
                        let mockUser = User(
                            id: "preview_user_id",
                            name: "プレビューユーザー",
                            inviteCode: "PREVIEW-CODE-123",
                            allowQRRegistration: true,
                            followingUserIds: []
                        )
                        let mockAuth = MockAuthenticationManager(
                            isAuthenticated: true,
                            isAnonymous: false,
                            currentUser: mockUser
                        )
                        return unsafeBitCast(mockAuth, to: AuthenticationManager.self)
                    }()
                )
                .previewDisplayName("Google認証済み状態")
        }
    }
}

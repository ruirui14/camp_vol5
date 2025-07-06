import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeShareView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: QRCodeShareViewModel
    @Environment(\.presentationMode) var presentationMode

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
            .onAppear {
                viewModel.updateAuthenticationManager(authenticationManager)
                // Google認証済みの場合、ユーザー情報を読み込み
                if authenticationManager.isGoogleAuthenticated {
                    authenticationManager.refreshCurrentUser()
                }
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
                    Text("このコードをスキャンして\nフォローしてもらいましょう")
                        .font(.headline)
                        .multilineTextAlignment(.center)

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

                    VStack(spacing: 8) {
                        Text("招待コード")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(inviteCode)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    Button(action: {
                        viewModel.generateNewInviteCode()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("新しいコードを生成")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
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

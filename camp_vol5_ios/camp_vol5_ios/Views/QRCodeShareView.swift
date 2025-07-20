import SwiftUI

struct QRCodeShareView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: QRCodeShareViewModel
    @Environment(\.presentationMode) var presentationMode

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
            .gradientNavigationBar(colors: [.main, .accent], titleColor: .white)
            .onAppear {
                viewModel.updateAuthenticationManager(authenticationManager)
                // Google認証済みの場合、ユーザー情報を読み込み
                if authenticationManager.isGoogleAuthenticated {
                    authenticationManager.refreshCurrentUser()
                }
            }
            .alert(viewModel.saveAlertTitle, isPresented: $viewModel.showingSaveAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.saveAlertMessage)
            }
            .alert("写真へのアクセス許可", isPresented: $viewModel.showingPermissionAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("QRコードを保存するには、設定で写真へのアクセスを許可してください。")
            }
        }
    }

    // MARK: - View Components

    private var authenticatedContent: some View {
        VStack(spacing: 30) {
            Spacer()

            if let inviteCode = viewModel.inviteCode {
                VStack(spacing: 40) {
                    //QRコード
                    Image(uiImage: viewModel.generateQRCode(from: inviteCode))
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

                    HStack(alignment: .top, spacing: 20) {
                        // 更新
                        Button(action: {
                            viewModel.generateNewInviteCode()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.text)
                                    .font(.title3)
                                Text("更新")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.text)
                            }
                            .frame(minWidth: 60)
                        }
                        // リンク
                        Button(action: {
                            UIPasteboard.general.string = inviteCode
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "link")
                                    .foregroundColor(.text)
                                    .font(.title3)
                                Text("リンクをコピー")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.text)
                            }
                            .frame(minWidth: 60)
                        }

                        // シェア
                        ShareLink(item: URL(string: "https://developer.apple.com/xcode/swiftui/")!)
                        {
                            VStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.text)
                                    .font(.title3)
                                Text("シェア")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.text)
                            }
                            .frame(minWidth: 60)
                        }

                        // 保存
                        Button(action: {
                            viewModel.saveQRCodeToPhotos()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.down.to.line")
                                    .foregroundColor(.text)
                                    .font(.title3)
                                Text("保存")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.text)
                            }
                            .frame(minWidth: 60)
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

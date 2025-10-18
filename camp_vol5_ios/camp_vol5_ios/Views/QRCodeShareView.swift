import SwiftUI

// MARK: - QRCodeShareButton
/// QRコードをシェアするためのボタンコンポーネント
/// Twitter投稿用の文言とQRコード画像を含むShareLinkを提供
private struct QRCodeShareButton: View {
    let qrCodeImage: UIImage
    let inviteCode: String

    private var shareMessage: String {
        """
        私の鼓動を聞いてみない？

        ▼招待コード
        \(inviteCode)

        https://apps.apple.com/jp/app/id1234567890

        #狂愛
        #推し活
        """
    }

    var body: some View {
        ShareLink(
            item: Image(uiImage: qrCodeImage),
            subject: Text("私の鼓動を聞いてみない？"),
            message: Text(shareMessage),
            preview: SharePreview(
                "QRコード",
                image: Image(uiImage: qrCodeImage)
            )
        ) {
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
    }
}

// MARK: - QRCodeShareView
struct QRCodeShareView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @ObservedObject var viewModel: QRCodeShareViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: QRCodeShareViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            authenticatedContent(viewModel: viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("戻る") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }

                    ToolbarItem(placement: .principal) {
                        Text("招待コードを管理")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .overlay(alignment: .top) {
                    NavigationBarGradient(safeAreaHeight: geometry.safeAreaInsets.top)
                }
                .alert(
                    viewModel.saveAlertTitle,
                    isPresented: $viewModel.showingSaveAlert
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.saveAlertMessage)
                }
                .alert(
                    "写真へのアクセス許可",
                    isPresented: $viewModel.showingPermissionAlert
                ) {
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

    private func authenticatedContent(viewModel: QRCodeShareViewModel) -> some View {
        VStack(spacing: 30) {
            Spacer()

            if let inviteCode = viewModel.inviteCode {
                VStack(spacing: 40) {
                    // QRコード
                    Group {
                        if let qrCodeImage = viewModel.qrCodeImage {
                            Image(uiImage: qrCodeImage)
                                .resizable()
                                .interpolation(.none)
                        } else {
                            Image(systemName: "qrcode")
                                .font(.system(size: 100))
                                .foregroundColor(.gray)
                        }
                    }
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

                    // QR登録許可トグル
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.blue)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("フォローを許可")
                                .font(.body.weight(.medium))
                                .foregroundColor(.text)
                        }

                        Spacer()

                        Toggle("", isOn: $viewModel.allowQRRegistration)
                            .labelsHidden()
                            .onChange(of: viewModel.allowQRRegistration) {
                                viewModel.toggleQRRegistration()
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal)

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
                                Text("IDをコピー")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.text)
                            }
                            .frame(minWidth: 60)
                        }

                        // シェア
                        if let qrCodeImage = viewModel.qrCodeImage {
                            QRCodeShareButton(
                                qrCodeImage: qrCodeImage,
                                inviteCode: inviteCode
                            )
                        }

                        // 保存
                        Button(action: {
                            viewModel.saveQRCodeToPhotos()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.down.to.line")
                                    .foregroundColor(.text)
                                    .font(.title3)
                                Text("画像を保存")
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
}

struct QRCodeShareView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthenticationManager()
        QRCodeShareView(viewModel: QRCodeShareViewModel(authenticationManager: authManager))
            .environmentObject(authManager)
    }
}

import SwiftUI

// MARK: - QRCodeShareButton
/// QRコードをシェアするためのボタンコンポーネント
private struct QRCodeShareButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
    @State private var isShowingShareSheet = false
    @State private var shareItems: [Any] = []

    init(viewModel: QRCodeShareViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            authenticatedContent(viewModel: viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbarBackground(.hidden, for: .navigationBar)
                .onAppear {
                    // 画面表示時にQRコードを遅延生成
                    viewModel.onViewAppear()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("戻る")
                            }
                        }
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
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
                .sheet(isPresented: $isShowingShareSheet) {
                    ShareSheet(activityItems: shareItems)
                }
        }
    }

    // MARK: - View Components

    private func authenticatedContent(viewModel: QRCodeShareViewModel) -> some View {
        VStack(spacing: 30) {
            Spacer()

            if let inviteCode = viewModel.inviteCode {
                VStack(spacing: 40) {
                    qrCodeView
                    qrRegistrationToggle
                    actionButtons(inviteCode: inviteCode)
                }
            } else {
                loadingView
            }

            errorMessageView

            Spacer()
        }
    }

    private var qrCodeView: some View {
        Group {
            if let qrCodeImage = viewModel.qrCodeImage {
                Image(uiImage: qrCodeImage)
                    .resizable()
                    .interpolation(.none)
                    .transition(.opacity)
            } else if viewModel.isGeneratingQRCode {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.main)
                    Text("QRコードを生成中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 250, height: 250)
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
        .shadow(color: .gray.opacity(0.3), radius: 8, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.3), value: viewModel.qrCodeImage != nil)
    }

    private var qrRegistrationToggle: some View {
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
    }

    private func actionButtons(inviteCode: String) -> some View {
        HStack(alignment: .top, spacing: 20) {
            refreshButton
            copyButton(inviteCode: inviteCode)
            shareButton(inviteCode: inviteCode)
            saveButton
        }
    }

    private var refreshButton: some View {
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
        .disabled(viewModel.isGeneratingQRCode || viewModel.isLoading)
    }

    private func copyButton(inviteCode: String) -> some View {
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
    }

    private func shareButton(inviteCode: String) -> some View {
        Group {
            if let qrCodeImage = viewModel.qrCodeImage {
                QRCodeShareButton {
                    let shareMessage = """
                        私の鼓動を聞いてみない？

                        ▼招待コード
                        \(inviteCode)

                        https://apps.apple.com/jp/app/id1234567890

                        #狂愛
                        #推し活
                        """
                    shareItems = [qrCodeImage, shareMessage]
                    isShowingShareSheet = true
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                        .font(.title3)
                    Text("シェア")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.gray)
                }
                .frame(minWidth: 60)
            }
        }
    }

    private var saveButton: some View {
        Button(action: {
            viewModel.saveQRCodeToPhotos()
        }) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.to.line")
                    .foregroundColor(viewModel.qrCodeImage != nil ? .text : .gray)
                    .font(.title3)
                Text("画像を保存")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(viewModel.qrCodeImage != nil ? .text : .gray)
            }
            .frame(minWidth: 60)
        }
        .disabled(viewModel.qrCodeImage == nil || viewModel.isGeneratingQRCode)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("招待コードを読み込み中...")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var errorMessageView: some View {
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
    }
}

// MARK: - ShareSheet
/// UIActivityViewControllerをSwiftUIで使用するためのラッパー
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 更新処理は不要
    }
}

struct QRCodeShareView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthenticationManager()
        QRCodeShareView(viewModel: QRCodeShareViewModel(authenticationManager: authManager))
            .environmentObject(authManager)
    }
}

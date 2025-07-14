import SwiftUI

struct QRCodeScannerView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: QRCodeScannerViewModel
    @State private var showingQRScanner = false
    @State private var showingFollowConfirmation = false
    @State private var showingAuthRequired = false
    @Environment(\.presentationMode) var presentationMode

    init() {
        _viewModel = StateObject(
            wrappedValue: QRCodeScannerViewModel(
                authenticationManager: AuthenticationManager()
            ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                manualInputSection(viewModel: viewModel)

                // QR Scanner Button
                qrScannerButton

                // Scanned User Info
                if let user = viewModel.scannedUser {
                    scannedUserSection(user: user)
                }

                // Error/Success Messages
                messageSection

                Spacer()
            }
            .padding()
            .navigationTitle("フォローユーザー追加")
            .navigationBarTitleDisplayMode(.inline)
            .gradientNavigationBar(colors: [.main, .accent], titleColor: .white)
            .onAppear {
                viewModel.updateAuthenticationManager(authenticationManager)
            }
            .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                print("shouldDismiss changed to: \(shouldDismiss)")
                if shouldDismiss {
                    print("Dismissing QRCodeScannerView")
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingQRScanner) {
                QRScannerSheet { code in
                    viewModel.handleQRCodeScan(code)
                    showingQRScanner = false
                }
            }
            .alert("フォロー確認", isPresented: $showingFollowConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("フォロー") {
                    viewModel.followUser()
                }
            } message: {
                if let user = viewModel.scannedUser {
                    Text("\(user.name)さんをフォローしますか？")
                }
            }
        }
    }

    // MARK: - View Components

    private var guestUserContent: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 16) {
                Text("1人以上のユーザーをフォローするには")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Google認証を行ってフル機能をお楽しみください")
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
        }
        .padding(.horizontal)
    }

    private func manualInputSection(viewModel: QRCodeScannerViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("招待コードを入力")
                .font(.headline)
                .foregroundColor(Color.text)

            HStack {
                TextField(
                    "招待コードを入力してください",
                    text: $viewModel.inviteCode
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)

                Button("検索") {
                    print("検索ボタンが押されました")
                    print(
                        "authenticationManager.isGoogleAuthenticated: \(authenticationManager.isGoogleAuthenticated)"
                    )
                    print("viewModel.inviteCode: \(viewModel.inviteCode)")
                    print("viewModel.isLoading: \(viewModel.isLoading)")

                    if authenticationManager.isGoogleAuthenticated {
                        viewModel.searchUserByInviteCode(viewModel.inviteCode)
                    } else {
                        showingAuthRequired = true
                    }
                }
                .buttonStyle(.bordered)
                // 入力されているかつローディング状態でない場合のみ表示させる
                .disabled(viewModel.inviteCode.isEmpty)

                // .disabled(viewModel.inviteCode.isEmpty || viewModel.isLoading)
            }
        }
    }

    private var qrScannerButton: some View {
        VStack(spacing: 12) {
            Divider()

            Text("または")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: {
                if authenticationManager.isGoogleAuthenticated {
                    showingQRScanner = true
                } else {
                    showingAuthRequired = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title2)
                    Text("QRコードで追加する")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.text)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.main, lineWidth: 1)
                )
            }
            .disabled(viewModel.isLoading)
        }
    }

    private func scannedUserSection(user: User) -> some View {
        VStack(spacing: 16) {
            Divider()

            VStack(spacing: 12) {
                // User Avatar Placeholder
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    )

                // User Info
                VStack(spacing: 4) {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("招待コード: \(user.inviteCode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .font(.system(.caption, design: .monospaced))
                }

                // Follow Status
                if viewModel.isFollowingUser {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("フォロー済み")
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(20)

                    Button("フォロー解除") {
                        viewModel.unfollowUser()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .disabled(viewModel.isLoading)

                } else {
                    Button("フォローする") {
                        showingFollowConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }

    private var messageSection: some View {
        VStack(spacing: 8) {
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
                .onTapGesture {
                    viewModel.clearError()
                }
            }

            if let successMessage = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.callout)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .onTapGesture {
                    viewModel.clearSuccessMessage()
                }
            }

            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("処理中...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}

// MARK: - Preview
struct QRCodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeScannerView()
            .environmentObject(AuthenticationManager())
    }
}

import SwiftUI

struct FollowUserView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel = FollowUserViewModel()
    @State private var showingQRScanner = false
    @State private var showingCameraConfirmation = false
    @State private var showingFollowConfirmation = false
    @State private var showingAuthRequired = false
    @State private var showingQRCodeShare = false
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geometry in
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .principal) {
                    Text("フォローユーザー追加")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .overlay(alignment: .top) {
                NavigationBarGradient(safeAreaHeight: geometry.safeAreaInsets.top)
            }
            .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .sheet(isPresented: $showingQRScanner) {
                QRScannerSheet { code in
                    viewModel.handleQRCodeScan(code)
                    showingQRScanner = false
                }
                .environmentObject(authenticationManager)
            }
            .sheet(isPresented: $showingQRCodeShare) {
                NavigationStack {
                    QRCodeShareView(
                        viewModel: QRCodeShareViewModel(
                            authenticationManager: authenticationManager)
                    )
                    .environmentObject(authenticationManager)
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
            .alert("認証が必要です", isPresented: $showingAuthRequired) {
                Button("キャンセル", role: .cancel) {}
                Button("認証する") {
                    authenticationManager.signInWithGoogle()
                }
            } message: {
                Text("この機能を利用するにはGoogle認証が必要です")
            }
            .alert("カメラの起動", isPresented: $showingCameraConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("はい") {
                    showingQRScanner = true
                }
            } message: {
                Text("QRコード読み取りのためにカメラが起動しますが、よろしいですか？")
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

    private func manualInputSection(viewModel: FollowUserViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("招待コードを入力")
                .font(.headline)
                .foregroundColor(Color.text)

            HStack(spacing: 8) {
                HStack {
                    TextField(
                        "招待コードを入力してください",
                        text: $inputText
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isInputFocused)
                    .onSubmit {
                        if !inputText.isEmpty {
                            viewModel.searchUserByInviteCode(inputText)
                            isInputFocused = false
                        }
                    }
                    .onChange(of: inputText) { _, _ in
                        viewModel.clearError()
                    }

                    // クリアボタン（入力がある場合のみ表示）
                    if !inputText.isEmpty {
                        Button(action: {
                            inputText = ""
                            isInputFocused = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                Button("検索") {
                    viewModel.searchUserByInviteCode(inputText)
                }
                .buttonStyle(.bordered)
                // 入力されているかつローディング状態でない場合のみ表示させる
                .disabled(inputText.isEmpty)

                // .disabled(inputText.isEmpty || viewModel.isLoading)
            }
        }
    }

    private var qrScannerButton: some View {
        VStack(spacing: 12) {
            Divider()

            Text("または")
                .font(.caption)
                .foregroundColor(.secondary)

            // QRコード読み取りボタン
            Button(action: {
                showingCameraConfirmation = true
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

            // 自分のQRコード表示ボタン
            Button(action: {
                if authenticationManager.isAuthenticated {
                    showingQRCodeShare = true
                } else {
                    showingAuthRequired = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.title2)
                    Text("招待コードを管理")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.accent)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.accent, lineWidth: 1)
                )
            }
            .disabled(viewModel.isLoading)
        }
    }

    private func scannedUserSection(user: User) -> some View {
        VStack(spacing: 12) {
            Divider()

            VStack(spacing: 8) {
                // User Info
                VStack(spacing: 2) {
                    Text(user.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("招待コード: \(user.inviteCode)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                // Follow Status
                if viewModel.isFollowingUser {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("フォロー済み")
                            .foregroundColor(.green)
                            .font(.footnote)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(16)

                    Button("フォロー解除") {
                        viewModel.unfollowUser()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                    .disabled(viewModel.isLoading)
                } else {
                    Button("フォローする") {
                        showingFollowConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
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

struct FollowUserView_Previews: PreviewProvider {
    static var previews: some View {
        FollowUserView()
            .environmentObject(AuthenticationManager())
    }
}

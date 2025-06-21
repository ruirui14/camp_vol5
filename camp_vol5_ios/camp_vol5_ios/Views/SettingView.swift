// Views/SettingsView.swift
import CoreImage.CIFilterBuiltins
import SwiftUI

struct SettingsView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                authStatusSection

                if authService.isGoogleAuthenticated {
                    userInfoSection
                    qrCodeSection
                    heartbeatSection
                }

                signOutSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                if authService.isGoogleAuthenticated {
                    viewModel.loadCurrentUser()
                }
            }
            .refreshable {
                if authService.isGoogleAuthenticated {
                    viewModel.loadCurrentUser()
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil))
            {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert(
                "成功",
                isPresented: .constant(viewModel.successMessage != nil)
            ) {
                Button("OK") {
                    viewModel.clearSuccessMessage()
                }
            } message: {
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                }
            }
        }
    }

    // MARK: - View Sections

    private var authStatusSection: some View {
        Section("認証状態") {
            HStack {
                Image(
                    systemName: authService.isGoogleAuthenticated
                        ? "checkmark.circle.fill" : "person.circle"
                )
                .foregroundColor(
                    authService.isGoogleAuthenticated ? .green : .orange
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        authService.isGoogleAuthenticated
                            ? "Google認証済み" : "ゲストユーザー"
                    )
                    .font(.headline)

                    if authService.isAnonymous {
                        Text("Google認証でフル機能が利用できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let firebaseUser = authService.user,
                        let email = firebaseUser.email
                    {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            if authService.isAnonymous {
                Button(action: {
                    authService.signInWithGoogle()
                }) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "globe")
                        }
                        Text(authService.isLoading ? "認証中..." : "Googleで認証")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(authService.isLoading)
            }

            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .onTapGesture {
                        authService.clearError()
                    }
            }
        }
    }

    private var userInfoSection: some View {
        Section("ユーザー情報") {
            if let user = viewModel.currentUser {
                HStack {
                    Text("名前")
                    Spacer()
                    Text(user.name)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("招待コード")
                    Spacer()
                    Text(user.inviteCode)
                        .foregroundColor(.secondary)
                        .font(.system(.caption, design: .monospaced))
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("ユーザー情報を読み込み中...")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var qrCodeSection: some View {
        Section("QRコード共有") {
            if let user = viewModel.currentUser {
                VStack(spacing: 15) {
                    if let qrImage = generateQRCode(from: user.inviteCode) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    Toggle("QR登録を許可する", isOn: $viewModel.allowQRRegistration)
                        .onChange(of: viewModel.allowQRRegistration) {
                            newValue in
                            viewModel.toggleQRRegistration()
                        }

                    Button("新しい招待コードを生成") {
                        viewModel.generateNewInviteCode()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)

                    Text(
                        viewModel.allowQRRegistration
                            ? "他のユーザーがあなたをフォローできます" : "QR登録は無効です"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var heartbeatSection: some View {
        Section("心拍データ") {
            HStack {
                VStack(alignment: .leading) {
                    Text("現在の心拍数")
                        .font(.headline)

                    if let heartbeat = viewModel.currentHeartbeat {
                        HStack {
                            Text("\(heartbeat.bpm) BPM")
                                .font(.title2)
                                .fontWeight(.bold)

                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                        }

                        Text("更新: \(formattedTime(heartbeat.timestamp))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("データなし")
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("更新") {
                    viewModel.refreshHeartbeat()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button(authService.isGoogleAuthenticated ? "サインアウト" : "アプリをリセット") {
                viewModel.signOut()
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.red)
        } footer: {
            if authService.isGoogleAuthenticated {
                Text("サインアウトすると、ゲストモードに戻ります。")
            } else {
                Text("アプリのデータをリセットして再起動します。")
            }
        }
    }

    // MARK: - Helper Methods

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(
                scaledImage,
                from: scaledImage.extent
            ) {
                return UIImage(cgImage: cgImage)
            }
        }

        return nil
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

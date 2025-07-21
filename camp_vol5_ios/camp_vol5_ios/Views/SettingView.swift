// Views/SettingsView.swift
import CoreImage.CIFilterBuiltins
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode

    init() {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                authenticationManager: AuthenticationManager()
            ))
    }

    var body: some View {
        GeometryReader { geometry in
            Form {
                authStatusSection

                if authenticationManager.isGoogleAuthenticated {
                    userInfoSection
                    qrCodeSection
                    heartbeatSection
                }

                signOutSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .overlay(alignment: .top) {
                NavigationBarGradient(safeAreaHeight: geometry.safeAreaInsets.top)
            }
            .onAppear {
                viewModel.updateAuthenticationManager(authenticationManager)
                if authenticationManager.isGoogleAuthenticated {
                    viewModel.loadCurrentUser()
                }
            }
            .refreshable {
                if authenticationManager.isGoogleAuthenticated {
                    viewModel.loadCurrentUser()
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
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
                    systemName: authenticationManager.isGoogleAuthenticated
                        ? "checkmark.circle.fill" : "person.circle"
                )
                .foregroundColor(
                    authenticationManager.isGoogleAuthenticated ? .green : .orange
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        authenticationManager.isGoogleAuthenticated
                            ? "Google認証済み" : "ゲストユーザー"
                    )
                    .font(.headline)

                    if authenticationManager.isAnonymous {
                        Text("Google認証でフル機能が利用できます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let firebaseUser = authenticationManager.user,
                        let email = firebaseUser.email
                    {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            if authenticationManager.isAnonymous {
                Button(action: {
                    authenticationManager.signInWithGoogle()
                }) {
                    HStack {
                        if authenticationManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "globe")
                        }
                        Text(authenticationManager.isLoading ? "認証中..." : "Googleで認証")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(authenticationManager.isLoading)
            }

            if let errorMessage = authenticationManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .onTapGesture {
                        authenticationManager.clearError()
                    }
            }
        }
    }

    private var userInfoSection: some View {
        Section("ユーザー情報") {
            UserInfoContent(viewModel: viewModel)
        }
    }
}

struct UserInfoContent: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
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

extension SettingsView {
    private var qrCodeSection: some View {
        Section("QRコード共有") {
            QRCodeContent(viewModel: viewModel)
        }
    }
}

struct QRCodeContent: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
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

                Toggle("QR登録を許可する", isOn: allowQRRegistrationBinding)
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

    private var allowQRRegistrationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.allowQRRegistration },
            set: { viewModel.allowQRRegistration = $0 }
        )
    }

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

}

struct HeartbeatContent: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(spacing: 20) {
            // ハートアニメーション表示
            if let heartbeat = viewModel.currentHeartbeat {
                HeartAnimationView(
                    bpm: heartbeat.bpm,
                    heartSize: 120,
                    showBPM: true,
                    enableHaptic: true,
                    heartColor: .red
                )
                .frame(height: 140)

                Text("更新: \(formattedTime(heartbeat.timestamp))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                HeartAnimationView(
                    bpm: 0,
                    heartSize: 120,
                    showBPM: true,
                    enableHaptic: false,
                    heartColor: .gray
                )
                .frame(height: 140)

                Text("データなし")
                    .foregroundColor(.secondary)
            }

            Button("更新") {
                viewModel.refreshHeartbeat()
            }
            .buttonStyle(.bordered)
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

extension SettingsView {
    private var heartbeatSection: some View {
        Section("心拍データ") {
            HeartbeatContent(viewModel: viewModel)
        }
    }

    private var signOutSection: some View {
        Section {
            Button(authenticationManager.isGoogleAuthenticated ? "サインアウト" : "アプリをリセット") {
                viewModel.signOut()
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.red)
        } footer: {
            if authenticationManager.isGoogleAuthenticated {
                Text("サインアウトすると、ゲストモードに戻ります。")
            } else {
                Text("アプリのデータをリセットして再起動します。")
            }
        }
    }

    // MARK: - Computed Properties

    private var allowQRRegistrationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.allowQRRegistration },
            set: { viewModel.allowQRRegistration = $0 }
        )
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

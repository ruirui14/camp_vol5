import Combine
// Views/SettingsView.swift
import CoreImage.CIFilterBuiltins
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var autoLockManager = AutoLockManager.shared
    @Environment(\.presentationMode) var presentationMode

    init() {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                authenticationManager: AuthenticationManager()
            )
        )
    }

    var body: some View {
        GeometryReader { geometry in
            Form {
                if authenticationManager.isAuthenticated {
                    settingsNavigationSection
                    signOutSection
                }
            }
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
                    Text("設定")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .overlay(alignment: .top) {
                NavigationBarGradient(safeAreaHeight: geometry.safeAreaInsets.top)
            }
            .onAppear {
                viewModel.updateAuthenticationManager(authenticationManager)
                if authenticationManager.isAuthenticated {
                    viewModel.loadCurrentUser()
                }
            }
            .refreshable {
                if authenticationManager.isAuthenticated {
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
            .onChange(of: authenticationManager.isAuthenticated) { isAuthenticated in
                // 認証状態が失われた場合（アカウント削除など）は設定画面を閉じる
                if !isAuthenticated {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    // MARK: - View Sections

    private var settingsNavigationSection: some View {
        Section {
            NavigationLink(destination: UserInfoSettingsView(viewModel: viewModel)) {
                SettingRow(
                    icon: "person.circle",
                    title: "ユーザー情報",
                    subtitle: "名前、招待コードの管理"
                )
            }

            NavigationLink(destination: UserNameEditView(viewModel: viewModel)) {
                SettingRow(
                    icon: "pencil.circle",
                    title: "ユーザー名変更",
                    subtitle: "表示名を変更します"
                )
            }

            NavigationLink(destination: HeartbeatSettingsView(viewModel: viewModel)) {
                SettingRow(
                    icon: "heart.circle",
                    title: "自分の心拍データ",
                    subtitle: "現在の心拍情報を確認"
                )
            }

            NavigationLink(destination: AutoLockSettingsView(autoLockManager: autoLockManager)) {
                SettingRow(
                    icon: "lock.circle",
                    title: "自動ロック無効化",
                    subtitle: "画面オフ設定の管理"
                )
            }

            NavigationLink(destination: TermsOfServiceView()) {
                SettingRow(
                    icon: "doc.text.circle",
                    title: "利用規約",
                    subtitle: "アプリの利用規約を確認"
                )
            }

            NavigationLink(destination: AccountDeletionView(viewModel: viewModel)) {
                SettingRow(
                    icon: "trash.circle",
                    title: "アカウント削除",
                    subtitle: "アカウントとデータを完全に削除"
                )
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button("サインアウト") {
                viewModel.signOut()
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.red)
        } footer: {
            Text("サインアウトすると、ログイン画面に戻ります。")
        }
    }
}

// MARK: - Supporting Views

struct UserInfoContent: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var authenticationManager: AuthenticationManager

    var body: some View {
        // 認証状態セクション
        HStack {
            Image(
                systemName: authenticationManager.isAuthenticated
                    ? "checkmark.circle.fill" : "person.circle"
            )
            .foregroundColor(
                authenticationManager.isAuthenticated ? .green : .orange
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    authenticationManager.isAuthenticated
                        ? "認証済み" : "未認証"
                )
                .font(.headline)

                if let firebaseUser = authenticationManager.user,
                    let email = firebaseUser.email
                {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("認証済みでフル機能が利用できます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }

        if let errorMessage = authenticationManager.errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .font(.caption)
                .onTapGesture {
                    authenticationManager.clearError()
                }
        }

        // ユーザー情報セクション
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

// MARK: - Setting Row Component

struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Individual Settings Views

struct UserInfoSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("ユーザー情報") {
                UserInfoContent(viewModel: viewModel)
            }
        }
        .navigationTitle("ユーザー情報")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HeartbeatSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("心拍データ") {
                HeartbeatContent(viewModel: viewModel)
            }
        }
        .navigationTitle("心拍データ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AutoLockSettingsView: View {
    @ObservedObject var autoLockManager: AutoLockManager

    var body: some View {
        Form {
            Section(
                header: Text("自動ロック設定"),
                footer: Text(
                    autoLockManager.autoLockDisabled
                        ? "指定した時間の間、iOSの自動ロックが無効になります。"
                        : "iOSの通常の自動ロック設定が適用されます。"
                )
            ) {
                Toggle("自動ロックを無効にする", isOn: $autoLockManager.autoLockDisabled)

                if autoLockManager.autoLockDisabled {
                    Picker("無効化時間", selection: $autoLockManager.autoLockDuration) {
                        ForEach(autoLockManager.availableDurations, id: \.self) { duration in
                            Text(autoLockManager.durationDisplayText(duration))
                                .tag(duration)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
        .navigationTitle("自動ロック")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: autoLockManager.autoLockDisabled) { isDisabled in
            autoLockManager.updateSettings(
                autoLockDisabled: isDisabled,
                duration: autoLockManager.autoLockDuration
            )
        }
        .onChange(of: autoLockManager.autoLockDuration) { duration in
            autoLockManager.updateSettings(
                autoLockDisabled: autoLockManager.autoLockDisabled,
                duration: duration
            )
        }
    }
}

struct UserNameEditView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var newUserName: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(
                header: Text("新しいユーザー名"),
                footer: Text("ユーザー名は20文字以内で入力してください")
            ) {
                TextField("新しいユーザー名", text: $newUserName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(isLoading)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            Section {
                Button(action: updateUserName) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.white)
                        }

                        Text(isLoading ? "更新中..." : "ユーザー名を更新")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .disabled(
                    isLoading || newUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
                .opacity(
                    newUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
        }
        .navigationTitle("ユーザー名変更")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            newUserName = viewModel.currentUser?.name ?? ""
        }
        .alert("成功", isPresented: .constant(successMessage != nil)) {
            Button("OK") {
                successMessage = nil
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            if let successMessage = successMessage {
                Text(successMessage)
            }
        }
    }

    private func updateUserName() {
        let trimmedName = newUserName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "ユーザー名を入力してください"
            return
        }

        guard trimmedName.count <= 20 else {
            errorMessage = "ユーザー名は20文字以内で入力してください"
            return
        }

        guard let currentUser = viewModel.currentUser else {
            errorMessage = "ユーザー情報が取得できません"
            return
        }

        isLoading = true
        errorMessage = nil

        // 新しいユーザー情報を作成
        let updatedUser = User(
            id: currentUser.id,
            name: trimmedName,
            inviteCode: currentUser.inviteCode,
            allowQRRegistration: currentUser.allowQRRegistration,
            followingUserIds: currentUser.followingUserIds,
            imageName: currentUser.imageName
        )

        // UserServiceを使ってユーザー情報を更新
        UserService.shared.updateUser(updatedUser)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case let .failure(error) = completion {
                        self.errorMessage = "更新に失敗しました: \(error.localizedDescription)"
                    }
                },
                receiveValue: { _ in
                    self.viewModel.currentUser = updatedUser
                    self.successMessage = "ユーザー名を更新しました"
                }
            )
            .store(in: &cancellables)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("最終更新日: 2024年1月1日")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    TermsSection(
                        title: "第1条（利用規約の適用）",
                        content:
                            "本利用規約は、Heart Beat Monitorアプリケーション（以下「本アプリ」といいます）の利用に関して適用されます。本アプリを利用することにより、お客様は本規約に同意したものとみなします。"
                    )

                    TermsSection(
                        title: "第2条（アプリの目的）",
                        content:
                            "本アプリは、心拍数をリアルタイムで共有し、健康管理とコミュニケーションを支援することを目的としています。医療診断や治療を目的としたものではありません。"
                    )

                    TermsSection(
                        title: "第3条（利用者の義務）",
                        content:
                            "利用者は以下の行為を行ってはなりません：\n• 本アプリを商用目的で利用すること\n• 他の利用者に迷惑をかける行為\n• システムの正常な動作を妨げる行為\n• 個人情報を不正に取得する行為"
                    )

                    TermsSection(
                        title: "第4条（プライバシー）",
                        content:
                            "本アプリは、お客様の心拍数データを収集・処理します。収集されたデータは、アプリの機能提供のためにのみ使用され、第三者に提供されることはありません。"
                    )

                    TermsSection(
                        title: "第5条（データの保存期間）",
                        content: "心拍数データは5分間のみ保存され、その後自動的に削除されます。ユーザー情報は、アカウントが削除されるまで保存されます。"
                    )

                    TermsSection(
                        title: "第6条（免責事項）",
                        content: "本アプリの利用により生じた損害について、開発者は一切の責任を負いません。本アプリは現状有姿で提供され、動作の保証はありません。"
                    )

                    TermsSection(
                        title: "第7条（利用規約の変更）",
                        content: "開発者は、必要に応じて本利用規約を変更することができます。変更後の利用規約は、本アプリ内での表示をもって効力を生じます。"
                    )

                    TermsSection(
                        title: "第8条（準拠法）",
                        content: "本利用規約は日本国法に準拠し、本アプリに関する紛争は、東京地方裁判所を第一審の専属管轄裁判所とします。"
                    )
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
    }
}

struct AccountDeletionView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showConfirmation = false
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var showFinalConfirmation = false

    private let requiredText = "削除する"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 警告セクション
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("重要な注意事項")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)

                            Text("この操作は取り消すことができません")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }

                // 削除される内容
                VStack(alignment: .leading, spacing: 16) {
                    Text("削除される内容")
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 12) {
                        DeletionItem(
                            icon: "person.circle",
                            title: "アカウント情報",
                            description: "ユーザー名、招待コードなどのプロフィール情報"
                        )

                        DeletionItem(
                            icon: "heart.circle",
                            title: "心拍データ",
                            description: "これまでに送信された心拍情報"
                        )

                        DeletionItem(
                            icon: "person.2.circle",
                            title: "フォロー関係",
                            description: "他のユーザーとのつながり情報"
                        )

                        DeletionItem(
                            icon: "photo.circle",
                            title: "カスタム背景画像",
                            description: "設定した背景画像とその編集情報"
                        )
                    }
                }

                // 確認入力セクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("削除を確認")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("アカウント削除を実行するには、下記のテキストフィールドに「\(requiredText)」と入力してください。")
                        .font(.body)
                        .foregroundColor(.secondary)

                    TextField("ここに入力", text: $confirmationText)
                        .textFieldStyle(ModernTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                // 削除ボタン
                Button(action: {
                    showFinalConfirmation = true
                }) {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "trash.fill")
                                .font(.title3)
                        }

                        Text(isDeleting ? "削除中..." : "アカウントを削除")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(confirmationText != requiredText || isDeleting)
                .opacity(confirmationText == requiredText && !isDeleting ? 1.0 : 0.6)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle("アカウント削除")
        .navigationBarTitleDisplayMode(.inline)
        .alert("最終確認", isPresented: $showFinalConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除する", role: .destructive) {
                performAccountDeletion()
            }
        } message: {
            Text("本当にアカウントを削除しますか？この操作は取り消すことができません。")
        }
        .alert(
            "エラー", isPresented: .constant(authenticationManager.errorMessage != nil && isDeleting)
        ) {
            Button("OK") {
                authenticationManager.clearError()
                isDeleting = false
            }
        } message: {
            if let errorMessage = authenticationManager.errorMessage {
                Text(errorMessage)
            }
        }
        .onChange(of: authenticationManager.isAuthenticated) { isAuthenticated in
            // アカウント削除が成功した場合（認証状態がfalseになった場合）
            // ContentViewが自動的にログイン画面に切り替えるため、何もする必要なし
            if !isAuthenticated && isDeleting {
                // AuthenticationManagerの状態変更により、ContentViewが自動的にAuthViewに切り替わる
                isDeleting = false
            }
        }
    }

    private func performAccountDeletion() {
        isDeleting = true
        authenticationManager.deleteAccount()
    }

}

struct DeletionItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.red)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

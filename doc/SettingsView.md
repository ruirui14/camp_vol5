# SettingsView - 設定画面

## 概要
アプリの各種設定を管理する画面。ユーザー情報の管理、心拍データの確認、アカウント操作を提供。

## 機能

### 設定項目
1. **ユーザー情報**
   - `UserInfoSettingsView`で認証状態とユーザー情報表示
   - 名前、招待コードの確認

2. **ユーザー名変更**
   - `UserNameEditView`での名前変更
   - 20文字以内の制限
   - リアルタイムバリデーション

3. **自分の心拍データ**
   - `HeartbeatSettingsView`で現在の心拍情報確認
   - `HeartAnimationView`での視覚的表示
   - 手動更新機能

4. **自動ロック無効化**
   - `AutoLockSettingsView`での自動ロック設定
   - 無効化時間の選択（5分〜60分）
   - リアルタイム設定反映

5. **利用規約**
   - `TermsOfServiceView`でアプリ利用規約表示
   - スクロール可能な規約内容

6. **アカウント削除**
   - `AccountDeletionView`での完全なアカウント削除
   - 2段階確認（テキスト入力 + 最終確認）
   - 削除対象データの詳細説明

### アカウント操作
- **サインアウト**: 認証状態のクリア
- **アカウント削除**: 全データの完全削除
  - ユーザー情報、心拍データ、フォロー関係、背景画像

## 詳細な内部処理

### SettingsViewModelの状態管理

**認証状態とユーザー情報の監視**:
```swift
private func setupBindings() {
    // 認証状態とローディング状態を組み合わせて監視
    Publishers.CombineLatest(
        authenticationManager.$isAuthenticated,
        authenticationManager.$isLoading
    )
    .receive(on: DispatchQueue.main)
    .sink { [weak self] isAuthenticated, isLoading in
        // 認証完了かつローディング終了時にユーザー情報読み込み
        if isAuthenticated, !isLoading {
            self?.loadCurrentUserIfNeeded()
        }
    }
    .store(in: &cancellables)
}
```

**ユーザー情報の自動更新**:
```swift
authenticationManager.$currentUser
    .receive(on: DispatchQueue.main)
    .sink { [weak self] user in
        self?.currentUser = user
        if let user = user {
            self?.inviteCode = user.inviteCode
            self?.allowQRRegistration = user.allowQRRegistration
        }
    }
    .store(in: &cancellables)
```

### データ読み込みとエラーハンドリング

**ユーザー情報取得の重複防止**:
```swift
private func loadCurrentUserIfNeeded() {
    guard let userId = authenticationManager.currentUserId else { return }

    UserService.shared.getUser(uid: userId)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                    // エラー時も空のユーザーオブジェクトでUI状態終了
                    self?.currentUser = User(
                        id: userId, name: "Unknown", inviteCode: "",
                        allowQRRegistration: false
                    )
                }
            },
            receiveValue: { [weak self] user in
                self?.currentUser = user
                if let user = user {
                    self?.loadCurrentHeartbeat()  // ユーザー情報取得後に心拍データ読み込み
                }
            }
        )
        .store(in: &cancellables)
}
```

### 心拍データの管理

**自動心拍データ読み込み**:
```swift
private func loadCurrentHeartbeat() {
    guard let userId = authenticationManager.currentUserId else { return }

    HeartbeatService.shared.getHeartbeatOnce(userId: userId)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] heartbeat in
                self?.currentHeartbeat = heartbeat
            }
        )
        .store(in: &cancellables)
}
```

**手動更新機能**:
```swift
func refreshHeartbeat() {
    guard let userId = authenticationManager.currentUserId else {
        errorMessage = "認証が必要です"
        return
    }
    loadCurrentHeartbeat()
}
```

### 招待コード管理

**新しい招待コード生成**:
```swift
func generateNewInviteCode() {
    guard let userId = authenticationManager.currentUserId,
          let currentUser = authenticationManager.currentUser else {
        errorMessage = "認証が必要です"
        return
    }

    isLoading = true

    UserService.shared.generateNewInviteCode(for: currentUser)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] newInviteCode in
                self?.inviteCode = newInviteCode
                self?.successMessage = "新しい招待コードを生成しました"
                // AuthenticationManager内の情報も更新
                self?.authenticationManager.refreshCurrentUser()
            }
        )
        .store(in: &cancellables)
}
```

### QR登録許可設定

**トグル設定の処理**:
```swift
func toggleQRRegistration() {
    guard let userId = authenticationManager.currentUserId,
          let currentUser = authenticationManager.currentUser else {
        errorMessage = "認証が必要です"
        return
    }

    let newValue = allowQRRegistration
    isLoading = true

    UserService.shared.updateQRRegistrationSetting(for: currentUser, allow: newValue)
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    // エラー時はトグルを元に戻す
                    self?.allowQRRegistration = !newValue
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.successMessage = newValue ? "QR登録を許可しました" : "QR登録を無効にしました"
                    self?.authenticationManager.refreshCurrentUser()
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
}
```

### ユーザー名変更の詳細処理

**UserNameEditViewでの更新処理**:
```swift
private func updateUserName() {
    let trimmedName = newUserName.trimmingCharacters(in: .whitespacesAndNewlines)

    // バリデーション
    guard !trimmedName.isEmpty else {
        errorMessage = "ユーザー名を入力してください"
        return
    }

    guard trimmedName.count <= 20 else {
        errorMessage = "ユーザー名は20文字以内で入力してください"
        return
    }

    // 新しいユーザー情報作成
    let updatedUser = User(
        id: currentUser.id,
        name: trimmedName,
        inviteCode: currentUser.inviteCode,
        allowQRRegistration: currentUser.allowQRRegistration,
        followingUserIds: currentUser.followingUserIds,
        imageName: currentUser.imageName
    )

    // 更新実行
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
```

### アカウント削除の安全措置

**2段階確認システム**:
```swift
struct AccountDeletionView: View {
    @State private var confirmationText = ""
    @State private var showFinalConfirmation = false
    private let requiredText = "削除する"

    var body: some View {
        // テキスト入力による確認
        TextField("ここに入力", text: $confirmationText)

        // 削除ボタンの有効化制御
        Button("アカウントを削除") {
            showFinalConfirmation = true
        }
        .disabled(confirmationText != requiredText || isDeleting)

        // 最終確認アラート
        .alert("最終確認", isPresented: $showFinalConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除する", role: .destructive) {
                performAccountDeletion()
            }
        }
    }
}
```

**削除処理とフォローアップ**:
```swift
private func performAccountDeletion() {
    isDeleting = true
    authenticationManager.deleteAccount()
}

.onChange(of: authenticationManager.isAuthenticated) { isAuthenticated in
    // アカウント削除成功時（認証状態がfalseに変化）
    if !isAuthenticated && isDeleting {
        isDeleting = false
        // ContentViewが自動的にAuthViewに切り替わる
    }
}
```

### 自動ロック管理

**AutoLockManagerとの連携**:
```swift
struct AutoLockSettingsView: View {
    @ObservedObject var autoLockManager: AutoLockManager

    var body: some View {
        Toggle("自動ロックを無効にする", isOn: $autoLockManager.autoLockDisabled)

        .onChange(of: autoLockManager.autoLockDisabled) { isDisabled in
            autoLockManager.updateSettings(
                autoLockDisabled: isDisabled,
                duration: autoLockManager.autoLockDuration
            )
        }
    }
}
```

## 重要な実装ポイント
- `@StateObject`で`SettingsViewModel`を管理
- 各設定項目への`NavigationLink`による遷移
- エラー・成功メッセージのアラート表示
- 認証状態変更時の自動画面クローズ
- Combineによる複数状態の統合監視
- エラー時の適切な状態復元処理
- 2段階確認によるアカウント削除の安全性
- リアルタイムバリデーションとUX最適化

## 関連ファイル
- `SettingsViewModel.swift` - 設定データ管理
- `AutoLockManager.swift` - 自動ロック制御
- `UserService.swift` - ユーザーデータ操作
- `AuthenticationManager.swift` - 認証状態管理
- `HeartbeatService.swift` - 心拍データ取得
- `ImagePersistenceService.swift` - 背景画像削除処理
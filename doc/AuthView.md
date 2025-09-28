# AuthView - 認証画面

## 概要
ユーザーがアプリを初回起動した際に表示される認証画面。複数の認証方法を提供する。

## 機能

### 認証方法
1. **匿名認証（体験利用）**
   - 「はじめる」ボタンで匿名ユーザーとしてアプリを体験
   - フル機能は利用できないが、基本的な機能を試せる

2. **Google認証**
   - Googleアカウントでログイン
   - フル機能が利用可能

3. **メール認証**
   - メールアドレスとパスワードでアカウント作成・ログイン
   - `EmailAuthView`をモーダル表示

### UI要素
- **ヒーローセクション**: アプリアイコン、アニメーション、タイトル
- **認証ボタン**: 各認証方法のボタン（アイコン、説明付き）
- **エラー表示**: 認証エラー時のメッセージ表示

### アニメーション
- アプリアイコンの拡大縮小アニメーション
- ハートアイコンの拍動アニメーション
- ボタンのスケールエフェクト

## 詳細な内部処理

### AuthViewModelの状態管理

**初期化とバインディング**:
```swift
@MainActor
class AuthViewModel: ObservableObject {
    @Published var selectedAuthMethod: AuthMethod = .none
    @Published var animateContent = false

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        setupBindings()
        startAnimation()  // 画面表示アニメーション開始
    }
}
```

**AuthenticationManagerとの連携**:
```swift
private func setupBindings() {
    // AuthenticationManagerの状態をViewModelに反映
    authenticationManager.$isLoading
        .receive(on: DispatchQueue.main)
        .assign(to: \.isLoading, on: self)
        .store(in: &cancellables)

    authenticationManager.$errorMessage
        .receive(on: DispatchQueue.main)
        .assign(to: \.errorMessage, on: self)
        .store(in: &cancellables)
}
```

### 認証フローの内部処理

**Google認証の流れ**:
```swift
func signInWithGoogle() {
    selectedAuthMethod = .google
    authenticationManager.selectedAuthMethod = "google"
    authenticationManager.signInWithGoogle()
}
```

**匿名認証の処理**:
```swift
func signInAnonymously() {
    selectedAuthMethod = .anonymous
    authenticationManager.selectedAuthMethod = "anonymous"
    authenticationManager.signInAnonymously()
}
```

**メール認証モーダル表示**:
```swift
func showEmailAuthModal() {
    selectedAuthMethod = .email
    authenticationManager.selectedAuthMethod = "email"
    showEmailAuth = true  // sheet(isPresented:)をトリガー
}
```

### UIアニメーションの制御

**継続的なアニメーション**:
```swift
// ハートアイコンの拍動アニメーション
Image(systemName: "heart.fill")
    .scaleEffect(viewModel.animateContent ? 1.1 : 1.0)
    .animation(
        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
        value: viewModel.animateContent
    )

// 背景円の拡大縮小
Circle()
    .scaleEffect(viewModel.animateContent ? 1.0 : 0.8)
    .animation(
        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
        value: viewModel.animateContent
    )
```

**状態に応じた透明度制御**:
```swift
.opacity(viewModel.animateContent ? 1.0 : 0.7)
```

### ボタンのインタラクティブ要素

**認証ボタンの状態管理**:
```swift
struct AuthButton: View {
    let isSelected: Bool
    let isLoading: Bool

    var body: some View {
        // ローディング中の表示切り替え
        if isLoading {
            ProgressView()
                .scaleEffect(0.8)
                .tint(color)
        } else {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
        }
    }
}
```

**ボタンの視覚フィードバック**:
```swift
.scaleEffect(isSelected ? 1.02 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
.shadow(
    color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.05),
    radius: isSelected ? 8 : 4
)
```

### エラーハンドリングと状態制御

**エラー表示コンポーネント**:
```swift
struct ErrorCard: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text("エラーが発生しました")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
    }
}
```

**エラーの自動クリア**:
```swift
func clearError() {
    authenticationManager.clearError()
    selectedAuthMethod = .none  // 選択状態もリセット
}
```

### モーダル表示の制御

**EmailAuthViewの表示**:
```swift
.sheet(
    isPresented: $viewModel.showEmailAuth,
    onDismiss: {
        viewModel.dismissEmailAuth()  // モーダル終了時の状態リセット
    }
) {
    EmailAuthView()
        .environmentObject(authenticationManager)
}
```

**モーダル終了処理**:
```swift
func dismissEmailAuth() {
    showEmailAuth = false
    selectedAuthMethod = .none  // 認証方法選択をリセット
}
```

### レスポンシブレイアウト

**GeometryReaderを使用した動的レイアウト**:
```swift
GeometryReader { geometry in
    VStack(spacing: 20) {
        // ヒーローセクションの高さを画面サイズに応じて調整
        .frame(height: geometry.size.height * 0.5)
    }
}
```

**デバイスサイズ対応**:
```swift
.padding(.horizontal, 24)  // 水平マージン
.frame(maxWidth: .infinity)  // 利用可能幅を最大活用
```

## 重要な実装ポイント
- `@StateObject`でAuthViewModelを管理
- モーダル表示で`EmailAuthView`を呼び出し
- エラーハンドリングと成功時の自動画面遷移
- レスポンシブデザインで各デバイスサイズに対応
- Combineを使ったAuthenticationManagerとの状態同期
- `@MainActor`による安全なUI更新
- 継続的アニメーションによる魅力的なUX
- 状態に応じた視覚フィードバック

## 関連ファイル
- `AuthViewModel.swift` - 認証ロジック
- `EmailAuthView.swift` - メール認証画面
- `AuthenticationManager.swift` - 認証状態管理
- `UserNameInputView.swift` - ユーザー名入力画面（認証後）
# ListHeartBeatsView - メイン画面（心拍数リスト）

## 概要
認証済みユーザーのメイン画面。フォロー中のユーザーの心拍数をリアルタイムで表示する。

## 機能

### 心拍数表示
- フォロー中のユーザーの心拍数を`UserHeartbeatCard`でリスト表示
- リアルタイム更新（5分間有効）
- カスタム背景画像表示対応

### ナビゲーション
- **設定画面**: ツールバー左のギアアイコン
- **QRスキャナー**: ツールバー右の人追加アイコン
- **心拍数詳細**: カードタップで詳細画面へ遷移

### 背景画像管理
- `BackgroundImageManager`でユーザーごとの背景画像を管理
- 永続化されたカスタム背景画像を読み込み
- 非同期での画像読み込みとキャッシュ

### データ更新
- Pull-to-refresh対応
- アプリフォアグラウンド復帰時の自動更新
- フォローユーザーデータ変更時の自動更新

### フォローユーザーなしの場合
- 空状態の表示
- QRスキャナーへの誘導

## 詳細な内部処理

### ViewModelとの連携
```swift
@StateObject private var viewModel: ListHeartBeatsViewModel
```

**認証状態監視**:
- `ListHeartBeatsViewModel`内でCombine publishersを使用
- `authenticationManager.$isAuthenticated`、`$isLoading`、`$currentUser`を同時監視
- `removeDuplicates`で重複実行を防止
- 認証完了時に自動的に`loadFollowingUsersWithHeartbeats()`を実行

**データ読み込みフロー**:
1. `UserService.shared.getFollowingUsers()` - フォロー中ユーザー情報取得
2. `flatMap`で各ユーザーの心拍データを並行取得
3. `HeartbeatService.shared.getHeartbeatOnce()` - 個別心拍データ取得
4. エラー時は`nil`心拍データでUserWithHeartbeatを作成
5. `Publishers.MergeMany().collect()`で全データを集約

### 背景画像の非同期読み込み

**重複防止メカニズム**:
```swift
@State private var isLoadingBackgroundImages = false
@State private var lastLoadTime: Date = .distantPast
@State private var hasLoadedOnce = false
```

**読み込み条件**:
- 既に読み込み中でない
- 初回読み込み以降は1秒間隔制限
- フォローユーザーデータが存在する

**BackgroundImageManager生成**:
```swift
private func loadBackgroundImages() {
    for userWithHeartbeat in viewModel.followingUsersWithHeartbeats {
        let userId = userWithHeartbeat.user.id
        if backgroundImageManagers[userId] == nil {
            // 新しいManagerを作成（初期化時に自動でloadPersistedImages()実行）
            backgroundImageManagers[userId] = BackgroundImageManager(userId: userId)
        }
    }
}
```

**BackgroundImageManager内部処理**:
1. `init(userId:)` - 初期化時に`loadPersistedImages()`自動実行
2. `UserDefaultsImageService`からメタデータ読み込み
3. `ImagePersistenceService`から実際の画像ファイル読み込み
4. バックグラウンドキューで処理、メインキューで@Published更新

### UserHeartbeatCardWrapperの遅延読み込み

**画像監視**:
```swift
.onChange(of: backgroundImageManager?.currentEditedImage) { newImage in
    if backgroundImage != newImage {
        updateBackgroundImage()
    }
}
```

**遅延読み込み対応**:
```swift
.task {
    await checkBackgroundImagePeriodically()
}

private func checkBackgroundImagePeriodically() async {
    for _ in 0..<10 {  // 最大5秒間
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5秒待機
        if let newImage = backgroundImageManager?.currentEditedImage {
            backgroundImage = newImage
            break
        }
    }
}
```

### UI更新トリガーシステム

**更新検知**:
```swift
@State private var uiUpdateTrigger = false

.onReceive(viewModel.$followingUsersWithHeartbeats) { usersWithHeartbeats in
    let needsLoading = usersWithHeartbeats.contains { userWithHeartbeat in
        let userId = userWithHeartbeat.user.id
        return backgroundImageManagers[userId] == nil ||
               backgroundImageManagers[userId]?.currentEditedImage == nil
    }
    if needsLoading {
        loadBackgroundImages()
    }
}
```

**トリガー発動**:
```swift
let hasNewImages = self.backgroundImageManagers.values.contains { manager in
    manager.currentEditedImage != nil
}
if hasNewImages {
    self.uiUpdateTrigger.toggle()  // SwiftUIの再描画をトリガー
}
```

### ライフサイクル管理

**画面表示時**:
```swift
.onAppear {
    viewModel.updateAuthenticationManager(authenticationManager)
    viewModel.loadFollowingUsersWithHeartbeats()
    if !viewModel.followingUsersWithHeartbeats.isEmpty {
        loadBackgroundImages()
    }
}
```

**フォアグラウンド復帰時**:
```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
    loadBackgroundImages()
}
```

## 重要な実装ポイント
- `@StateObject`で`ListHeartBeatsViewModel`を管理
- `NavigationDestination`enumでタイプセーフなナビゲーション
- 背景画像の遅延読み込みと重複防止ロジック
- UI更新トリガーによる再描画制御
- Combineを使った複数状態の監視と非同期処理
- メモリ効率を考慮したBackgroundImageManagerの遅延初期化

## 関連ファイル
- `ListHeartBeatsViewModel.swift` - データ管理ロジック
- `UserHeartbeatCard.swift` - 個別カードコンポーネント
- `BackgroundImageManager.swift` - 背景画像管理
- `ImagePersistenceService.swift` - 画像ファイル永続化
- `UserDefaultsImageService.swift` - 画像メタデータ管理
- `HeartbeatDetailView.swift` - 詳細画面
- `SettingsView.swift` - 設定画面
- `QRCodeScannerView.swift` - QRスキャナー画面
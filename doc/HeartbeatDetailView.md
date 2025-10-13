# HeartbeatDetailView - 心拍数詳細画面

## 概要
特定のユーザーの心拍数をリアルタイムで詳細表示し、振動や画面設定を制御できる画面。

## 機能

### 心拍数表示
- `HeartAnimationView`でリアルタイム心拍数アニメーション
- 最終更新時刻の表示
- 有効な心拍データがない場合の「No data available」表示

### 背景カスタマイズ
- **カード背景編集**: `CardBackgroundEditView`で背景設定
- **背景画像編集**: `ImageEditView`で全画面背景設定
- **背景画像リセット**: 設定した画像の削除
- ドラッグ・ズーム操作での画像位置調整

### 振動機能
- 心拍に同期した振動パターン
- 振動のON/OFF切り替え
- `VibrationService`による振動制御
- 有効なBPM値のみ振動対応

### 画面制御
- **スリープモード**: 手動で画面を暗転
- **自動ロック無効化**: 指定時間の自動ロック無効
- **ステータスバー制御**: 隠す/表示の切り替え
- 残り時間表示

### リアルタイム監視
- `HeartbeatDetailViewModel`での継続的データ監視
- 画面表示中のみリアルタイム更新
- 画面離脱時のリソース解放

## 詳細な内部処理

### HeartbeatDetailViewModelのリアルタイム監視

**初期化処理**:
```swift
init(userId: String) {
    self.userId = userId
    loadUserInfo()  // ユーザー情報を非同期取得
}
```

**ユーザー情報取得**:
```swift
private func loadUserInfo() {
    UserService.shared.getUser(uid: userId)
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                self.errorMessage = error.localizedDescription
            }
        }, receiveValue: { user in
            self.user = user
        })
        .store(in: &cancellables)
}
```

**継続的心拍監視**:
```swift
func startContinuousMonitoring() {
    guard !isMonitoring else { return }

    isMonitoring = true
    heartbeatSubscription = HeartbeatService.shared.subscribeToHeartbeat(userId: userId)
        .receive(on: DispatchQueue.main)
        .sink { heartbeat in
            self.currentHeartbeat = heartbeat
        }
}
```

### VibrationServiceの心拍振動制御

**心拍パターン振動**:
```swift
func startHeartbeatVibration(bpm: Int) {
    let interval = 60.0 / Double(bpm)  // BPMから振動間隔計算

    vibrationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {
        self.triggerHeartbeatPattern()
    }
}
```

**「ドクン」パターンの実現**:
```swift
private func triggerHeartbeatPattern() {
    // 1回目: 強い振動（ドク）
    let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    heavyImpact.impactOccurred()

    // 2回目: 0.12秒後に中程度の振動（ン）
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
        let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
        mediumImpact.impactOccurred()
    }
}
```

**UIアニメーション同期**:
```swift
let heartbeatTrigger = PassthroughSubject<Void, Never>()

private func triggerHeartbeatPattern() {
    heartbeatTrigger.send()  // HeartAnimationViewとの同期
    // ... 振動処理
}
```

### 画面制御とライフサイクル

**スリープモード切り替え**:
```swift
private func toggleSleepMode() {
    isSleepMode.toggle()
    isStatusBarHidden = isSleepMode
    isPersistentSystemOverlaysHidden = isSleepMode ? .hidden : .automatic
}
```

**自動ロック制御**:
```swift
.onAppear {
    if autoLockManager.autoLockDisabled {
        autoLockManager.enableAutoLockDisabling()  // iOSの自動ロック無効化
    }
}

.onDisappear {
    autoLockManager.disableAutoLockDisabling()  // 自動ロック設定復元
}
```

**振動とデータの連携**:
```swift
.onChange(of: viewModel.currentHeartbeat) { heartbeat in
    if isVibrationEnabled {
        if let heartbeat = heartbeat, vibrationService.isValidBPM(heartbeat.bpm) {
            vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
        } else {
            vibrationService.stopVibration()
        }
    }
}
```

### 編集モーダルとの連携

**フルスクリーンモーダルでの編集**:
```swift
.fullScreenCover(isPresented: $showingImageEditor, onDismiss: {
    // ImageEditView終了時の処理
    let heartPosition = persistenceManager.loadHeartPosition()
    heartOffset = heartPosition
    heartSize = persistenceManager.loadHeartSize()
    savedBackgroundColor = persistenceManager.loadBackgroundColor()

    // 振動再開
    if isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
        if vibrationService.isValidBPM(heartbeat.bpm) {
            vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
        }
    }
})
```

**編集中の振動停止**:
```swift
Button("カード背景を編集") {
    vibrationService.stopVibration()  // 編集中は振動停止
    showingCardBackgroundEditSheet = true
}
```

### データ永続化との連携

**画面表示時の設定復元**:
```swift
.onAppear {
    loadPersistedData()
    savedBackgroundColor = persistenceManager.loadBackgroundColor()

    // 初期振動設定
    if isVibrationEnabled, let heartbeat = viewModel.currentHeartbeat {
        if vibrationService.isValidBPM(heartbeat.bpm) {
            vibrationService.startHeartbeatVibration(bpm: heartbeat.bpm)
        }
    }
}
```

**永続化データ読み込み**:
```swift
private func loadPersistedData() {
    if let savedImage = persistenceManager.loadBackgroundImage() {
        selectedImage = savedImage
        editedImage = savedImage
    }

    let transform = persistenceManager.loadImageTransform()
    imageOffset = transform.offset
    imageScale = transform.scale

    let heartPosition = persistenceManager.loadHeartPosition()
    heartOffset = heartPosition
    heartSize = persistenceManager.loadHeartSize()
}
```

### メモリ管理とリソース解放

**ViewModelのdeinit**:
```swift
deinit {
    stopMonitoring()  // リアルタイム監視停止
}

func stopMonitoring() {
    isMonitoring = false
    heartbeatSubscription?.cancel()
    heartbeatSubscription = nil
    HeartbeatService.shared.unsubscribeFromHeartbeat(userId: userId)
}
```

**画面離脱時のクリーンアップ**:
```swift
.onDisappear {
    viewModel.stopMonitoring()      // リアルタイム監視停止
    vibrationService.stopVibration()  // 振動停止
    autoLockManager.disableAutoLockDisabling()  // 自動ロック設定復元
}
```

## 重要な実装ポイント
- フルスクリーンモーダルでの編集画面表示
- `@Binding`でのステータスバー状態制御
- 振動と画面制御の競合回避
- メモリリーク防止のための適切なライフサイクル管理
- リアルタイム監視とタイマーベース振動の同期
- 編集モーダル表示時の状態保存・復元
- UIImpactFeedbackGeneratorを使った自然な心拍振動パターン

## 関連ファイル
- `HeartbeatDetailViewModel.swift` - データ監視ロジック
- `VibrationService.swift` - 振動制御
- `AutoLockManager.swift` - 自動ロック制御
- `CardBackgroundEditView.swift` - カード背景編集
- `ImageEditView.swift` - 画像編集
- `PersistenceManager.swift` - データ永続化
- `HeartAnimationView.swift` - ハートアニメーション
- `HeartbeatService.swift` - リアルタイム心拍データ取得
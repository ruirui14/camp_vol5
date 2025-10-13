# CardBackgroundEditView - カード背景編集画面

## 概要
`UserHeartbeatCard`の背景をカスタマイズするための編集画面。画像とカラーピッカーでの背景設定機能を提供。

## 機能

### 背景カスタマイズ
1. **背景画像設定**
   - `PhotoPicker`での写真ライブラリからの画像選択
   - ドラッグ&ドロップでの画像位置調整
   - ピンチジェスチャーでのズーム調整
   - カード範囲外は半透明、範囲内は不透明での表示

2. **背景色設定**
   - `ColorPicker`での背景色選択
   - リアルタイムプレビュー
   - 画像との組み合わせ表示

3. **画像操作**
   - 同時ドラッグ・拡大縮小操作
   - 「リセット」で初期位置・サイズに戻す
   - 透過効果での配置プレビュー

### プレビュー機能
- `UserHeartbeatCard`でのリアルタイムプレビュー
- カード範囲のマスク表示
- 「プレビュー」「72 BPM」でのサンプル表示

### データ永続化
- 編集内容の自動保存
- 画像位置・スケールの保持
- 背景色の設定保存

## 重要な実装ポイント
- `CardConstants`を使用した一貫したカードサイズ
- `SimultaneousGesture`での複数ジェスチャー同時処理
- マスクを使用したカード範囲での透過制御
- `@StateObject`でのViewModel管理

## 関連ファイル
- `CardBackgroundEditViewModel.swift` - 編集ロジック
- `BackgroundImageManager.swift` - 画像管理
- `UserHeartbeatCard.swift` - プレビュー表示
- `CardConstants.swift` - カードサイズ定数
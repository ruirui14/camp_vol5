# Cloud Functions - Heartbeat Notification System

## 概要
Realtime Databaseの`live_heartbeats/{userId}`への書き込みを監視し、フォロワーにプッシュ通知を送信するCloud Functions。

## ファイル構成

```
functions/
├── src/                      # TypeScriptソースコード
│   ├── index.ts             # メイン関数（TypeScript）
│   └── types.ts             # 型定義
├── lib/                      # ビルド後のJavaScript（自動生成）
│   ├── index.js
│   ├── index.d.ts
│   ├── types.js
│   └── types.d.ts
├── tsconfig.json            # TypeScript設定
├── .eslintrc.js             # ESLint設定
├── .prettierrc              # Prettier設定
└── package.json             
```

## 機能

### onHeartbeatUpdate
- **トリガー**: `live_heartbeats/{userId}`への書き込み
- **処理内容**:
  1. レート制限チェック（5分間隔）
  2. フォロワー一覧の取得
  3. 通知有効なフォロワーのFCMトークンを収集
  4. プッシュ通知送信
  5. 最終通知送信時刻の更新

## データ構造

### Realtime Database
```
live_heartbeats/
  {userId}/
    bpm: number
    timestamp: number (ミリ秒)
    lastNotificationSent: number (ミリ秒)
```

### Firestore
```
users/
  {userId}/
    followers/
      {followerId}/
        followerId: string
        fcmToken: string
        notificationEnabled: boolean
        createdAt: timestamp
    following/
      {followingId}/
        followingId: string
        createdAt: timestamp
```

## セットアップ

### 1. 依存関係のインストール
```bash
cd functions
pnpm install
```

### 2. Firebase CLIのインストール（未インストールの場合）
```bash
pnpm install -g firebase-tools
```

### 3. Firebaseプロジェクトの初期化
```bash
firebase login
firebase use --add  # プロジェクトを選択
```

### 4. デプロイ
```bash
pnpm run deploy
```

## ローカル開発

### エミュレータの起動
```bash
pnpm run serve
```

### ログの確認
```bash
pnpm run logs
```

## 環境変数
特に設定は不要です。Firebase Admin SDKが自動的にプロジェクトの認証情報を使用します。

## レート制限
- 通知送信間隔: 5分（`NOTIFICATION_COOLDOWN_MS`で変更可能）
- `live_heartbeats/{userId}/lastNotificationSent`に最終送信時刻を保存

## エラーハンドリング
- FCMトークンが無効な場合はログに記録
- ユーザーが見つからない場合はスキップ
- フォロワーが存在しない場合はスキップ

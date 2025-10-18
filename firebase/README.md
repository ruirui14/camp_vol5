# Firebase 設定ファイル

このディレクトリには、Firebaseのセキュリティルールとインデックス定義が含まれています。

## ファイル構成

```
firebase/
├── database.rules.json       # Realtime Database のセキュリティルール
├── firestore.rules           # Cloud Firestore のセキュリティルール
├── firestore.indexes.json    # Cloud Firestore のインデックス定義
└── README.md                 # このファイル
```

## database.rules.json

Realtime Databaseのセキュリティルールを定義しています。主にリアルタイム心拍データの管理に使用されます。

## firestore.rules

Cloud Firestoreのセキュリティルールを定義しています。ユーザー情報とフォロー機能の管理に使用されます。

## firestore.indexes.json

Cloud Firestoreの複合インデックス定義を管理しています。現在定義されているインデックス：

- **users コレクション**: `inviteCode` + `allowQRRegistration`
  - QRコードによるユーザー検索クエリで使用
  - `FirestoreUserRepository.findByInviteCode()` で必要

## デプロイ方法

### セキュリティルールのみをデプロイ

```bash
# Firestoreルールのみ
firebase deploy --only firestore:rules

# Firestoreインデックスのみ
firebase deploy --only firestore:indexes

# Firestoreルールとインデックスを両方デプロイ
firebase deploy --only firestore

# Realtime Databaseルールのみ
firebase deploy --only database

# すべてのルールとインデックスをデプロイ
firebase deploy --only firestore,database
```

### すべてをデプロイ

```bash
firebase deploy
```

## 参考リンク

- [Realtime Database セキュリティルール](https://firebase.google.com/docs/database/security)
- [Cloud Firestore セキュリティルール](https://firebase.google.com/docs/firestore/security/get-started)
- [セキュリティルールのテスト](https://firebase.google.com/docs/rules/unit-tests)

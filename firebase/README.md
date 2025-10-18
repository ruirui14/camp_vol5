# Firebase セキュリティルール

このディレクトリには、Firebaseのセキュリティルールファイルが含まれています。

## ファイル構成

```
firebase/
├── database.rules.json    # Realtime Database のセキュリティルール
├── firestore.rules        # Cloud Firestore のセキュリティルール
└── README.md              # このファイル
```

## database.rules.json

Realtime Databaseのセキュリティルールを定義しています。主にリアルタイム心拍データの管理に使用されます。

## firestore.rules

Cloud Firestoreのセキュリティルールを定義しています。ユーザー情報とフォロー機能の管理に使用されます。

## デプロイ方法

### セキュリティルールのみをデプロイ

```bash
# Firestoreルールのみ
firebase deploy --only firestore:rules

# Realtime Databaseルールのみ
firebase deploy --only database

# 両方のルールをデプロイ
firebase deploy --only firestore:rules,database
```

### すべてをデプロイ

```bash
firebase deploy
```

## 参考リンク

- [Realtime Database セキュリティルール](https://firebase.google.com/docs/database/security)
- [Cloud Firestore セキュリティルール](https://firebase.google.com/docs/firestore/security/get-started)
- [セキュリティルールのテスト](https://firebase.google.com/docs/rules/unit-tests)

//
//  Error+Localization.swift
//  camp_vol5_ios
//
//  Firebase Authのエラーメッセージを日本語化するExtension
//
//  機能:
//  - Firebase Authの各種エラーコードを日本語メッセージに変換
//  - その他のエラーについてはデフォルトメッセージを返す
//

import FirebaseAuth
import Foundation

extension Error {
    /// Firebase Authのエラーを日本語化して返す
    var localizedJapaneseDescription: String {
        let nsError = self as NSError
        let errorCode = nsError.code

        // Firebase Authのエラーコード
        // https://github.com/firebase/firebase-ios-sdk/blob/9099f7fba6d506f95a6fbbc402c89a4165496e8a/FirebaseAuth/Sources/Public/FirebaseAuth/FIRAuthErrors.h#L84-L437
        switch errorCode {
        // 認証エラー（正しいエラーコード）
        case 17000:  // FIRAuthErrorCodeInvalidCustomToken
            return "カスタムトークンが無効です"
        case 17002:  // FIRAuthErrorCodeCustomTokenMismatch
            return "カスタムトークンが一致しません"
        case 17004:  // FIRAuthErrorCodeInvalidCredential
            return "認証情報が無効です"
        case 17005:  // FIRAuthErrorCodeUserDisabled
            return "このアカウントは無効化されています"
        case 17006:  // FIRAuthErrorCodeOperationNotAllowed
            return "この操作は許可されていません"
        case 17007:  // FIRAuthErrorCodeEmailAlreadyInUse
            return "このメールアドレスは既に使用されています"
        case 17008:  // FIRAuthErrorCodeInvalidEmail
            return "メールアドレスの形式が正しくありません"
        case 17009:  // FIRAuthErrorCodeWrongPassword
            return "パスワードが正しくありません"
        case 17010:  // FIRAuthErrorCodeTooManyRequests
            return "リクエストが多すぎます。しばらく待ってから再度お試しください"
        case 17011:  // FIRAuthErrorCodeUserNotFound
            return "このメールアドレスは登録されていません"
        case 17012:  // FIRAuthErrorCodeAccountExistsWithDifferentCredential
            return "このメールアドレスは既に別の認証方法で登録されています"
        case 17014:  // FIRAuthErrorCodeRequiresRecentLogin
            return "この操作には再ログインが必要です"
        case 17015:  // FIRAuthErrorCodeProviderAlreadyLinked
            return "このプロバイダーは既にリンクされています"
        case 17016:  // FIRAuthErrorCodeNoSuchProvider
            return "このプロバイダーはリンクされていません"
        case 17017:  // FIRAuthErrorCodeInvalidUserToken
            return "ユーザートークンが無効です"
        case 17020:  // FIRAuthErrorCodeNetworkError
            return "ネットワークエラーが発生しました。接続を確認してください"
        case 17021:  // FIRAuthErrorCodeUserTokenExpired
            return "認証トークンの有効期限が切れました。再度ログインしてください"
        case 17023:  // FIRAuthErrorCodeInvalidAPIKey
            return "APIキーが無効です"
        case 17024:  // FIRAuthErrorCodeUserMismatch
            return "ユーザー情報が一致しません"
        case 17025:  // FIRAuthErrorCodeCredentialAlreadyInUse
            return "この認証情報は既に使用されています"
        case 17026:  // FIRAuthErrorCodeWeakPassword
            return "パスワードが脆弱です。より強力なパスワードを設定してください"
        case 17028:  // FIRAuthErrorCodeAppNotAuthorized
            return "このアプリは認証されていません"
        case 17029:  // FIRAuthErrorCodeExpiredActionCode
            return "この確認コードは有効期限切れです"
        case 17030:  // FIRAuthErrorCodeInvalidActionCode
            return "確認コードが無効です"
        case 17031:  // FIRAuthErrorCodeInvalidMessagePayload
            return "メッセージのペイロードが無効です"
        case 17032:  // FIRAuthErrorCodeInvalidSender
            return "送信者のメールアドレスが無効です"
        case 17033:  // FIRAuthErrorCodeInvalidRecipientEmail
            return "受信者のメールアドレスが無効です"
        case 17034:  // FIRAuthErrorCodeMissingEmail
            return "メールアドレスを入力してください"
        case 17041:  // FIRAuthErrorCodeMissingPhoneNumber
            return "電話番号を入力してください"
        case 17042:  // FIRAuthErrorCodeInvalidPhoneNumber
            return "電話番号が無効です"
        case 17043:  // FIRAuthErrorCodeMissingVerificationCode
            return "認証コードを入力してください"
        case 17044:  // FIRAuthErrorCodeInvalidVerificationCode
            return "認証コードが正しくありません"
        case 17045:  // FIRAuthErrorCodeMissingVerificationID
            return "認証IDが見つかりません"
        case 17046:  // FIRAuthErrorCodeInvalidVerificationID
            return "認証IDが無効です"
        case 17051:  // FIRAuthErrorCodeSessionExpired
            return "SMSコードの有効期限が切れました"
        case 17052:  // FIRAuthErrorCodeQuotaExceeded
            return "SMS送信の上限を超えました。しばらく待ってから再度お試しください"
        case 17057:  // FIRAuthErrorCodeWebContextAlreadyPresented
            return "認証画面が既に表示されています"
        case 17058:  // FIRAuthErrorCodeWebContextCancelled
            return "認証がキャンセルされました"
        case 17071:  // FIRAuthErrorCodeInvalidProviderID
            return "プロバイダーIDが無効です"
        case 17078:  // FIRAuthErrorCodeSecondFactorRequired
            return "2段階認証が必要です"
        case 17086:  // FIRAuthErrorCodeUnverifiedEmail
            return "メールアドレスが確認されていません"
        case 17995:  // FIRAuthErrorCodeKeychainError
            return "キーチェーンエラーが発生しました"
        case 17999:  // FIRAuthErrorCodeInternalError
            return "内部エラーが発生しました"

        // Google Sign-In エラー
        case -4:  // GIDSignInErrorCodeCanceled
            return "Google認証がキャンセルされました"
        case -1:  // GIDSignInErrorCodeUnknown
            return "Google認証で不明なエラーが発生しました"
        case -2:  // GIDSignInErrorCodeKeychain
            return "Google認証でキーチェーンエラーが発生しました"
        case -5:  // GIDSignInErrorCodeEMM
            return "Google認証でEMMエラーが発生しました"

        default:
            // その他のエラーは元のメッセージを返す
            return nsError.localizedDescription
        }
    }
}

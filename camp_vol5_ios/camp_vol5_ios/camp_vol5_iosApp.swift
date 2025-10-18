import Firebase
import FirebaseAppCheck
import FirebaseCore
import FirebaseCrashlytics
import FirebaseMessaging
import FirebasePerformance
import GoogleSignIn
import SwiftUI
import UserNotifications

@main
struct camp_vol5_iosApp: App {
    // AppDelegate を追加
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // アプリケーション状態管理
    @StateObject private var appStateManager = AppStateManager()

    // AuthenticationManager をStateObjectとして管理
    @StateObject private var authenticationManager = AuthenticationManager()

    // ViewModelFactory をStateObjectとして管理
    @StateObject private var viewModelFactory: ViewModelFactory

    init() {
        // App Check を最初に設定（Firebase.configure() の前に必須）
        #if DEBUG
            // デバッグビルドの場合はDebugProviderを使用
            let providerFactory = AppCheckDebugProviderFactory()
            // デバッグトークンをコンソールに出力
            print("🔐 App Check Debug Mode - Check console for debug token")
        #else
            // リリースビルドの場合はApp Attestを使用
            let providerFactory = AppAttestProviderFactory()
        #endif
        AppCheck.setAppCheckProviderFactory(providerFactory)

        // Firebase を設定
        FirebaseApp.configure()

        // Crashlytics を初期化
        // 自動クラッシュレポート収集を有効化
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

        // Performance Monitoring を有効化（自動的に開始）
        Performance.sharedInstance().isDataCollectionEnabled = true
        print("🎯 Firebase Performance Monitoring enabled")

        let authManager = AuthenticationManager()
        _authenticationManager = StateObject(wrappedValue: authManager)
        _viewModelFactory = StateObject(
            wrappedValue: ViewModelFactory(
                authenticationManager: authManager,
                userService: UserService.shared,
                heartbeatService: HeartbeatService.shared,
                vibrationService: VibrationService.shared
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            switch appStateManager.currentState {
            case .splash:
                SplashView()
            case .main:
                ContentView()
                    .environmentObject(authenticationManager)
                    .environmentObject(viewModelFactory)
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
            }
        }
    }
}

// AppDelegate クラスを追加
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate,
    MessagingDelegate
{
    // ConnectivityManager を初期化してWatch連携を開始
    var connectivityManager = ConnectivityManager()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        // Firebase設定は App struct の init() で行うため、ここでは不要

        // プッシュ通知の設定
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // プッシュ通知の許可をリクエスト
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if let error = error {
                    print("❌ プッシュ通知の許可エラー: \(error.localizedDescription)")
                    return
                }
                if granted {
                    print("✅ プッシュ通知が許可されました")
                } else {
                    print("⚠️ プッシュ通知が拒否されました")
                }
            }
        )

        // APNsに登録
        application.registerForRemoteNotifications()

        return true
    }

    func application(
        _: UIApplication,
        open url: URL,
        options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - APNs Token

    func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ APNs token 登録成功")
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ APNs token 登録失敗: \(error.localizedDescription)")
    }

    // MARK: - MessagingDelegate

    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ FCM token: \(fcmToken ?? "nil")")

        // トークンをNotificationServiceに保存する処理は、
        // ログイン後にAuthenticationManagerで実行
    }

    // MARK: - UNUserNotificationCenterDelegate

    // フォアグラウンドで通知を受信した時
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
            -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("📱 フォアグラウンド通知受信: \(userInfo)")

        // フォアグラウンドでも通知を表示
        completionHandler([[.banner, .sound, .badge]])
    }

    // 通知をタップした時
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("👆 通知タップ: \(userInfo)")

        // TODO: 通知タップ時の処理（ユーザー画面への遷移など）

        completionHandler()
    }
}

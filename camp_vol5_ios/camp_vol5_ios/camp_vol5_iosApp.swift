import Firebase
import FirebaseAppCheck
import FirebaseCore
import FirebaseCrashlytics
import GoogleSignIn
import SwiftUI

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
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        // Firebase設定は App struct の init() で行うため、ここでは不要
        return true
    }

    func application(
        _: UIApplication,
        open url: URL,
        options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

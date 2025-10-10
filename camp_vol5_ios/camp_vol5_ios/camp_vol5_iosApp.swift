import Firebase
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

    var body: some Scene {
        WindowGroup {
            switch appStateManager.currentState {
            case .splash:
                SplashView()
            case .main:
                ContentView()
                    .environmentObject(authenticationManager)
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
        // Firebase設定
        FirebaseConfig.shared.configure()
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

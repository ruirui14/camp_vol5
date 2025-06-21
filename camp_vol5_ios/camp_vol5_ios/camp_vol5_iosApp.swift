import SwiftUI
import FirebaseCore

@main
struct camp_vol5_iosApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    @StateObject private var authViewModel = AuthViewModel()
        @StateObject private var connectivityManager = ConnectivityManager()
        
        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(connectivityManager)
            }
        }}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        if authViewModel.isAuthenticated {
            // ログイン済みの場合のメインビュー
            MainTabView()
        } else {
            // 未ログインの場合のログインビュー
            LoginView()
        }
    }
}

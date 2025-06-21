import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // HomeView の代わりに一時的なプレースホルダー
            NavigationView {
                VStack {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                .navigationTitle("ホーム")
            }
            .tabItem {
                Label("ホーム", systemImage: "house")
            }
            
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
    }
}

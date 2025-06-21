import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // 初期化時に既存の認証状態をチェック
        checkAuthenticationStatus()
    }
    
    private func checkAuthenticationStatus() {
        // 実際の認証チェックロジック
        // 例: UserDefaultsやKeychainから保存された認証情報を確認
        if let savedUserData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: savedUserData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func signIn(withEmail email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // 実際のサインインロジック
        // ここでは簡単なダミー実装
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 成功時の例
            let user = User(
                id: UUID().uuidString,
                name: "既存ユーザー",
                inviteCode: "EXIST123",
                allowQRRegistration: true
            )
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
            
            // ユーザー情報を保存
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
        }
    }
    
    func createUser(name: String, email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // ここに実際のユーザー作成ロジックを実装
        // Firebase Authでのユーザー作成 + Firestoreへのユーザー情報保存
        
        // 一時的なダミー実装（実際のFirebase実装に置き換えてください）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 招待コードを生成（実際のロジックに合わせて調整）
            let inviteCode = self.generateInviteCode()
            
            let newUser = User(
                id: UUID().uuidString, // 実際にはFirebase AuthのUIDを使用
                name: name,
                inviteCode: inviteCode,
                allowQRRegistration: true
            )
            
            self.currentUser = newUser
            self.isAuthenticated = true
            self.isLoading = false
            
            // ユーザー情報を保存
            if let userData = try? JSONEncoder().encode(newUser) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    func createDummyUser() {
        let dummyUser = User(
            id: UUID().uuidString,
            name: "テストユーザー",
            inviteCode: "TEST123",
            allowQRRegistration: true
        )
        self.currentUser = dummyUser
        self.isAuthenticated = true
        
        // ダミーユーザーも保存
        if let userData = try? JSONEncoder().encode(dummyUser) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    // 招待コード生成のヘルパーメソッド
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map{ _ in characters.randomElement()! })
    }
}

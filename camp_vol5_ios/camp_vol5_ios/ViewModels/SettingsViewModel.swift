import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    
    @Published var user: User = .empty
    @Published var userName: String = ""
    
    private let userDefaultsKey = "currentUserProfile"
    
    init() {
        loadUser()
    }
    
    /// ユーザーデータをUserDefaultsから読み込む
    func loadUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            // データがない場合は、空のユーザーで初期化
            self.user = .empty
            setupBindings()
            return
        }
        
        if let decodedUser = try? JSONDecoder().decode(User.self, from: data) {
            self.user = decodedUser
        } else {
            self.user = .empty
        }
        setupBindings()
    }
    
    /// ユーザーデータをUserDefaultsに保存する
    func saveUser() {
        // Viewの入力内容をモデルに反映
        user.name = userName
        
        if let encodedData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsKey)
            print("ユーザー情報を保存しました: \(user.name)")
        }
    }
    
    /// モデルのデータをView用のプロパティに反映させる
    private func setupBindings() {
        self.userName = user.name

    }
}

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ログイン")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                TextField("メールアドレス", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("パスワード", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if authViewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Button("ログイン") {
                        authViewModel.signIn(withEmail: email, password: password)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty)
                }
                
                // テスト用のダミーログインボタン
                Button("ダミーユーザーでログイン") {
                    authViewModel.createDummyUser()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

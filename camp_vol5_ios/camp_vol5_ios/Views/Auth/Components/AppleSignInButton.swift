// Views/Auth/Components/AppleSignInButton.swift
// Appleサインインボタン
// Apple Sign In認証用のカスタムボタン

import SwiftUI

struct AppleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .tint(.blue)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                Text("Appleでサインイン")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

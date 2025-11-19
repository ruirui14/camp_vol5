// Views/Auth/Components/AnonymousSignInButton.swift
// 匿名サインインボタン
// ゲストユーザー向けの匿名認証ボタン

import SwiftUI

struct AnonymousSignInButton: View {
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
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                }

                Text("匿名ではじめる")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "3c4043"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(hex: "f2f2f2"))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

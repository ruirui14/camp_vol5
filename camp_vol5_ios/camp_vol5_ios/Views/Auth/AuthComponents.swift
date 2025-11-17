// Views/Auth/AuthComponents.swift
// 認証画面で使用する共通コンポーネント
// ボタン、アニメーション、エラーバナー等

import SwiftUI

// MARK: - ハートビートアニメーション

struct HeartbeatAnimation: View {
    let isAnimating: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            // 外側の円（波紋効果）
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .scaleEffect(pulse ? 1.8 : 1.0)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.5),
                        value: pulse
                    )
            }

            // グラスモーフィズム背景
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .pink.opacity(0.5), radius: 20, x: 0, y: 10)

            // ハートアイコン
            Image(systemName: "heart.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(Color.accent)
                .scaleEffect(pulse ? 1.15 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: pulse
                )
                .shadow(color: Color.accent.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .onAppear {
            pulse = true
        }
    }
}

// MARK: - エラーバナー

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(hex: "FF6B6B"))
                .font(.title3)

            Text(message)
                .font(.callout)
                .foregroundColor(.white)
                .fontWeight(.medium)
                .lineLimit(3)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.title3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FF6B6B").opacity(0.4),
                            Color(hex: "EE5A6F").opacity(0.3),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "FF6B6B").opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color(hex: "FF6B6B").opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Googleサインインボタン

struct GoogleSignInButton: View {
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
                    Image("GoogleLogo")
                        .padding(.trailing, -15)
                }

                Text("Googleでサインイン")
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

// MARK: - Appleサインインボタン

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

// MARK: - 匿名サインインボタン

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

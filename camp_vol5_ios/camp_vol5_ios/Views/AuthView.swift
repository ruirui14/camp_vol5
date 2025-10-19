// AuthView.swift
// ログイン画面 - モダンでキュートなデザイン
// 心拍数をテーマにしたアニメーションと、グラスモーフィズム効果を採用

import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @EnvironmentObject private var viewModelFactory: ViewModelFactory
    @StateObject private var viewModel: AuthViewModel

    let onStartWithoutAuth: () -> Void

    init(
        onStartWithoutAuth: @escaping () -> Void,
        factory: ViewModelFactory
    ) {
        self.onStartWithoutAuth = onStartWithoutAuth
        self._viewModel = StateObject(
            wrappedValue: factory.makeAuthViewModel()
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // デフォルトのグラデーション背景
                MainAccentGradient()

                // 浮遊する円（背景装飾）
                FloatingCircles()

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)

                        // ヒーローセクション
                        VStack(spacing: 32) {
                            // ハートアニメーション
                            HeartbeatAnimation(isAnimating: viewModel.animateContent)
                                .frame(width: 140, height: 140)

                            // タイトル
                            VStack(spacing: 12) {
                                Text("狂愛")
                                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, Color.white.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                                    .scaleEffect(viewModel.animateContent ? 1.0 : 0.95)

                                Text("推しの心拍数を感じよう")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                            }
                            .opacity(viewModel.animateContent ? 1.0 : 0.7)
                            .animation(
                                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                                value: viewModel.animateContent
                            )
                        }
                        .padding(.top, 60)
                        .frame(height: geometry.size.height * 0.45)

                        // 認証ボタンセクション
                        VStack(spacing: 16) {
                            // はじめるボタン（ゲストモード）
                            GlassButton(
                                icon: "play.circle.fill",
                                title: "はじめる",
                                subtitle: "認証なしでアプリを体験",
                                color: .white
                            ) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    viewModel.signInAnonymously()
                                }
                            }

                            // 区切り線
                            HStack {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white.opacity(0.4))
                                    .frame(height: 1)
                                Text("または")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white.opacity(0.4))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)

                            // メール認証ボタン
                            GlassButton(
                                icon: "envelope.fill",
                                title: "メールで続ける",
                                subtitle: "メールアドレスで新規作成・ログイン",
                                color: Color(hex: "FFD93D"),
                                isSelected: viewModel.selectedAuthMethod == .email
                            ) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    viewModel.showEmailAuthModal()
                                }
                            }

                            // Google認証ボタン（標準デザイン）
                            StandardGoogleSignInButton(
                                isLoading: viewModel.isGoogleLoading
                            ) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    viewModel.signInWithGoogle()
                                }
                            }
                            .disabled(viewModel.isLoading)

                            // Apple認証ボタン（標準デザイン）
                            StandardAppleSignInButton(
                                isLoading: viewModel.isAppleLoading
                            ) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    viewModel.signInWithApple()
                                }
                            }
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // エラー表示
                        if let errorMessage = viewModel.errorMessage {
                            ErrorBanner(message: errorMessage) {
                                viewModel.clearError()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .sheet(
            isPresented: $viewModel.showEmailAuth,
            onDismiss: {
                viewModel.dismissEmailAuth()
            }
        ) {
            EmailAuthView(factory: viewModelFactory)
                .environmentObject(authenticationManager)
                .environmentObject(viewModelFactory)
        }
    }
}

// MARK: - 浮遊する円の背景装飾

struct FloatingCircles: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 30)
                .offset(x: animate ? -50 : 50, y: animate ? -100 : 100)
                .animation(
                    .easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: animate
                )

            Circle()
                .fill(Color.pink.opacity(0.15))
                .frame(width: 150, height: 150)
                .blur(radius: 25)
                .offset(x: animate ? 100 : -100, y: animate ? 150 : -150)
                .animation(
                    .easeInOut(duration: 5).repeatForever(autoreverses: true).delay(0.5),
                    value: animate
                )

            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 180, height: 180)
                .blur(radius: 35)
                .offset(x: animate ? -80 : 80, y: animate ? 200 : -200)
                .animation(
                    .easeInOut(duration: 6).repeatForever(autoreverses: true).delay(1),
                    value: animate
                )
        }
        .onAppear {
            animate = true
        }
    }
}

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

// MARK: - グラスモーフィズムボタン

struct GlassButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isSelected: Bool = false
    var isLoading: Bool = false
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
            HStack(spacing: 16) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    if isLoading {
                        ProgressView()
                            .tint(color)
                    } else {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    }
                }

                // テキスト
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.35 : 0.25),
                                Color.white.opacity(isSelected ? 0.25 : 0.15),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.3),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            // swiftlint:disable multiline_arguments
            .shadow(
                color: color.opacity(0.25), radius: isSelected ? 15 : 10, x: 0,
                y: isSelected ? 8 : 5)
            // swiftlint:enable multiline_arguments
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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

// MARK: - 標準的なGoogleサインインボタン（Appleボタンと統一デザイン）

struct StandardGoogleSignInButton: View {
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
                        .tint(Color(hex: "4285F4"))
                } else {
                    Image("GoogleLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)  // Appleロゴと同じサイズ感（.title2相当）
                }

                Text("Google でサインイン")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "3c4043"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)  // Appleボタンと同じ高さ
            .background(Color(hex: "f2f2f2"))
            .cornerRadius(12)  // Appleボタンと同じ角丸
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)  // Appleボタンと同じシャドウ
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)  // Appleボタンと同じスケール
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)  // Appleボタンと同じアニメーション
    }
}

// MARK: - 標準的なAppleサインインボタン

struct StandardAppleSignInButton: View {
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
                        .tint(.white)
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
            .frame(height: 50)  // Googleボタンと同じ高さ
            .background(Color.black)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthenticationManager()
        let factory = ViewModelFactory(
            authenticationManager: authManager,
            userService: UserService.shared,
            heartbeatService: HeartbeatService.shared,
            vibrationService: VibrationService.shared
        )
        return AuthView(onStartWithoutAuth: {}, factory: factory)
            .environmentObject(authManager)
            .environmentObject(factory)
    }
}

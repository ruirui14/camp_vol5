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
        ZStack {
            // デフォルトのグラデーション背景
            MainAccentGradient()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 30)

                    // ヒーローセクション
                    VStack(spacing: 24) {
                        // ハートアニメーション
                        HeartbeatAnimation(isAnimating: viewModel.animateContent)
                            .frame(width: 100, height: 100)

                        // タイトル
                        VStack(spacing: 8) {
                            Text("狂愛")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
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
                                .font(.body)
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
                    .padding(.top, 30)
                    .padding(.bottom, 20)

                    // 認証ボタンセクション
                    VStack(spacing: 16) {
                        // メール認証フォーム（常に表示）
                        EmailAuthFormView(viewModel: viewModel)

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

                        // 匿名認証ボタン（標準デザイン）
                        AnonymousSignInButton(
                            isLoading: viewModel.isAnonymousLoading
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                viewModel.signInAnonymously()
                            }
                        }
                        .disabled(authenticationManager.isLoading)

                        // Google認証ボタン（標準デザイン）
                        GoogleSignInButton(
                            isLoading: viewModel.isGoogleLoading
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                viewModel.signInWithGoogle()
                            }
                        }
                        .disabled(authenticationManager.isLoading)

                        // Apple認証ボタン（標準デザイン）
                        AppleSignInButton(
                            isLoading: viewModel.isAppleLoading
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                viewModel.signInWithApple()
                            }
                        }
                        .disabled(authenticationManager.isLoading)
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
        .sheet(isPresented: $viewModel.showPasswordReset) {
            PasswordResetView(viewModel: viewModel)
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

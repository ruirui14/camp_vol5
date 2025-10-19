// Services/AuthenticationProtocol.swift
// 認証機能のプロトコル定義

import Combine
import FirebaseAuth

// MARK: - Authentication Protocol

/// 認証機能のプロトコル（テスト用の抽象化）
protocol AuthenticationProtocol: ObservableObject {
    var user: FirebaseAuth.User? { get }
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isGoogleAuthenticated: Bool { get }
    var currentUserId: String? { get }

    func signInWithGoogle()
    func signInWithApple()
    func signInWithEmail(email: String, password: String)
    func signUpWithEmail(email: String, password: String, name: String)
    func signInAnonymously()
    func signOut()
    func refreshCurrentUser()
    func updateCurrentUser(_ user: User)
    func clearError()
    func deleteAccount()
}

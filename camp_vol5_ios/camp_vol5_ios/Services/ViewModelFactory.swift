// Services/ViewModelFactory.swift
// ViewModelの生成を一元管理するファクトリークラス
// 依存性注入を簡潔にし、テスタビリティを向上させる
// プロトコルベースの設計でモック可能な構造を実現

import Foundation

/// ViewModelの生成を一元管理するファクトリークラス
@MainActor
class ViewModelFactory: ObservableObject {
    // MARK: - Dependencies

    private let authenticationManager: AuthenticationManager
    private let userService: UserServiceProtocol
    private let heartbeatService: HeartbeatServiceProtocol
    private let vibrationService: any VibrationServiceProtocol

    // MARK: - Initialization

    init(
        authenticationManager: AuthenticationManager,
        userService: UserServiceProtocol,
        heartbeatService: HeartbeatServiceProtocol,
        vibrationService: any VibrationServiceProtocol
    ) {
        self.authenticationManager = authenticationManager
        self.userService = userService
        self.heartbeatService = heartbeatService
        self.vibrationService = vibrationService
    }

    // MARK: - Factory Methods

    /// ListHeartBeatsViewModelを生成
    func makeListHeartBeatsViewModel() -> ListHeartBeatsViewModel {
        ListHeartBeatsViewModel(
            authenticationManager: authenticationManager,
            userService: userService,
            heartbeatService: heartbeatService
        )
    }

    /// SettingsViewModelを生成
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            authenticationManager: authenticationManager,
            userService: userService,
            heartbeatService: heartbeatService
        )
    }

    /// FollowUserViewModelを生成
    func makeFollowUserViewModel() -> FollowUserViewModel {
        FollowUserViewModel(
            authenticationManager: authenticationManager,
            userService: userService
        )
    }

    /// QRCodeShareViewModelを生成
    func makeQRCodeShareViewModel() -> QRCodeShareViewModel {
        QRCodeShareViewModel(authenticationManager: authenticationManager)
    }

    /// HeartbeatDetailViewModelを生成
    /// - Parameter userId: ユーザーID
    func makeHeartbeatDetailViewModel(userId: String) -> HeartbeatDetailViewModel {
        HeartbeatDetailViewModel(
            userId: userId,
            userService: userService,
            heartbeatService: heartbeatService,
            vibrationService: vibrationService
        )
    }

    /// CardBackgroundEditViewModelを生成
    /// - Parameter userId: ユーザーID
    func makeCardBackgroundEditViewModel(userId: String) -> CardBackgroundEditViewModel {
        CardBackgroundEditViewModel(userId: userId)
    }

    /// UserNameInputViewModelを生成
    /// - Parameter selectedAuthMethod: 選択された認証方法
    func makeUserNameInputViewModel(
        selectedAuthMethod: SelectedAuthMethod
    ) -> UserNameInputViewModel {
        UserNameInputViewModel(
            selectedAuthMethod: selectedAuthMethod,
            authenticationManager: authenticationManager,
            userService: userService
        )
    }

    /// AuthViewModelを生成
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authenticationManager: authenticationManager)
    }

    /// EmailAuthViewModelを生成
    func makeEmailAuthViewModel() -> EmailAuthViewModel {
        EmailAuthViewModel(authenticationManager: authenticationManager)
    }

    /// StreamViewModelを生成
    /// - Parameter heartbeatDetailViewModel: 心拍データを共有するHeartbeatDetailViewModel
    func makeStreamViewModel(heartbeatDetailViewModel: HeartbeatDetailViewModel) -> StreamViewModel
    {
        StreamViewModel(heartbeatDetailViewModel: heartbeatDetailViewModel)
    }

    /// ConnectionsRankingViewModelを生成
    func makeConnectionsRankingViewModel() -> ConnectionsRankingViewModel {
        ConnectionsRankingViewModel(userService: userService)
    }
}

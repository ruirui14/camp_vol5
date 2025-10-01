// Services/BackgroundImageCoordinator.swift
// 複数ユーザーの背景画像管理を統括するコーディネーター
// 背景画像の読み込み、管理、UI更新トリガーを統一管理

import Foundation
import SwiftUI

@MainActor
class BackgroundImageCoordinator: ObservableObject {
    @Published var backgroundImageManagers: [String: BackgroundImageManager] = [:]
    @Published var uiUpdateTrigger = false

    private var isLoadingBackgroundImages = false
    private var lastLoadTime: Date = .distantPast
    private var hasLoadedOnce = false

    // MARK: - Public Methods

    func loadBackgroundImages(for users: [UserWithHeartbeat]) {
        let now = Date()

        // 重複呼び出し防止
        if isLoadingBackgroundImages {
            print("=== SKIPPING BACKGROUND IMAGES LOAD (already loading) ===")
            return
        }

        // 初回読み込み以降は、最後の読み込みから1秒以内の場合はスキップ
        if hasLoadedOnce && now.timeIntervalSince(lastLoadTime) < 1.0 {
            print("=== SKIPPING BACKGROUND IMAGES LOAD (too recent) ===")
            return
        }

        isLoadingBackgroundImages = true
        lastLoadTime = now
        print("=== LOADING BACKGROUND IMAGES ===")

        Task {
            await loadImagesTask(for: users)
        }
    }

    func needsLoading(for users: [UserWithHeartbeat]) -> Bool {
        return users.contains { userWithHeartbeat in
            let userId = userWithHeartbeat.user.id
            return backgroundImageManagers[userId] == nil
                || backgroundImageManagers[userId]?.currentEditedImage == nil
        }
    }

    func refreshFromStorage() {
        for manager in backgroundImageManagers.values {
            if manager.currentEditedImage == nil && !manager.isLoading {
                manager.refreshFromStorage()
            }
        }
    }

    // MARK: - Private Methods

    private func loadImagesTask(for users: [UserWithHeartbeat]) async {
        for userWithHeartbeat in users {
            let userId = userWithHeartbeat.user.id
            print(
                "Loading background image for user: \(userWithHeartbeat.user.name) (ID: \(userId))")

            await createOrRefreshManager(for: userId, userName: userWithHeartbeat.user.name)

            // BackgroundImageManagerの初期化を少し待つ
            try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3秒待機

            let hasImage = backgroundImageManagers[userId]?.currentEditedImage != nil
            print("  Image loaded for \(userWithHeartbeat.user.name): \(hasImage)")
        }

        await finalizeLoading()
    }

    private func createOrRefreshManager(for userId: String, userName: String) async {
        if backgroundImageManagers[userId] == nil {
            // 新しいManagerを作成
            print("  Creating new manager for \(userId)")
            backgroundImageManagers[userId] = BackgroundImageManager(userId: userId)
        } else {
            // 既存のManagerがある場合は、初回読み込み以降のみrefreshを実行
            if hasLoadedOnce, let existingManager = backgroundImageManagers[userId] {
                if existingManager.currentEditedImage == nil && !existingManager.isLoading {
                    print("  Refreshing existing manager for \(userId) (no image loaded)")
                    existingManager.refreshFromStorage()
                } else {
                    print("  Existing manager for \(userId) already has image or is loading")
                }
            } else {
                print("  Skipping refresh for \(userId) during initial load")
            }
        }
    }

    private func finalizeLoading() async {
        print("=== BACKGROUND IMAGES LOADED ===")

        // 実際に新しい画像が読み込まれた場合のみUI更新をトリガー
        let hasNewImages = backgroundImageManagers.values.contains { manager in
            manager.currentEditedImage != nil
        }

        if hasNewImages {
            uiUpdateTrigger.toggle()
        }

        // 読み込み完了フラグをリセット
        isLoadingBackgroundImages = false
        hasLoadedOnce = true
    }
}

// Views/Components/UserHeartbeatCardWrapper.swift
// ユーザーハートビートカードのラッパーコンポーネント - 背景画像管理との統合を担当
// SwiftUIベストプラクティスに従い、非同期での画像読み込みと状態管理を実装

import SwiftUI

struct UserHeartbeatCardWrapper: View {
    let userWithHeartbeat: UserWithHeartbeat
    let backgroundImageManager: BackgroundImageManager?
    @State private var backgroundImage: UIImage?

    init(userWithHeartbeat: UserWithHeartbeat, backgroundImageManager: BackgroundImageManager?) {
        self.userWithHeartbeat = userWithHeartbeat
        self.backgroundImageManager = backgroundImageManager

        let initialImage = backgroundImageManager?.currentEditedImage
        print("📱 [UserHeartbeatCardWrapper] init for user: \(userWithHeartbeat.user.name)")
        print(
            "📱 [UserHeartbeatCardWrapper] init - backgroundImageManager: \(backgroundImageManager != nil ? "存在" : "nil")"
        )
        print(
            "📱 [UserHeartbeatCardWrapper] init - initialImage: \(initialImage != nil ? "存在" : "nil")"
        )

        // 初期化時点で画像が既に利用可能な場合は設定
        self._backgroundImage = State(initialValue: initialImage)
    }

    var body: some View {
        UserHeartbeatCard(
            userWithHeartbeat: userWithHeartbeat,
            customBackgroundImage: backgroundImage,
            displayName: nil,
            displayBPM: nil
        )
        .onAppear {
            print("📱 [UserHeartbeatCardWrapper] onAppear for user: \(userWithHeartbeat.user.name)")
            // onAppearでは画像が既にnilでない場合は更新しない（無限ループ防止）
            if backgroundImage == nil {
                updateBackgroundImage()
            }
        }
        .onChange(of: backgroundImageManager?.currentEditedImage) { newImage in
            // 現在の画像と新しい画像が異なる場合のみ更新
            if backgroundImage != newImage {
                print(
                    "📱 [UserHeartbeatCardWrapper] currentEditedImage onChange for user: \(userWithHeartbeat.user.name), hasImage: \(newImage != nil)"
                )
                updateBackgroundImage()
            }
        }
        .task {
            // 非同期でバックグラウンド画像の読み込み完了を待つ
            await checkBackgroundImagePeriodically()
        }
    }

    private func updateBackgroundImage() {
        let newImage = backgroundImageManager?.currentEditedImage

        // 同じ画像の場合は更新をスキップ
        guard backgroundImage != newImage else { return }

        print(
            "📱 [UserHeartbeatCardWrapper] updateBackgroundImage for user: \(userWithHeartbeat.user.name), hasImage: \(newImage != nil)"
        )
        backgroundImage = newImage
    }

    @MainActor
    private func checkBackgroundImagePeriodically() async {
        // 最初の画像が利用可能かチェック
        if backgroundImage == nil {
            for _ in 0..<10 {  // 最大5秒間（0.5秒間隔で10回）
                try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5秒待機

                if let newImage = backgroundImageManager?.currentEditedImage,
                    backgroundImage != newImage
                {  // 重複更新チェック
                    print(
                        "📱 [UserHeartbeatCardWrapper] 遅延読み込み成功 for user: \(userWithHeartbeat.user.name)"
                    )
                    backgroundImage = newImage
                    break
                }
            }
        }
    }
}

#Preview {
    UserHeartbeatCardWrapper(
        userWithHeartbeat: UserWithHeartbeat(
            user: User(id: "test", name: "Test User"),
            heartbeat: nil
        ),
        backgroundImageManager: nil
    )
}

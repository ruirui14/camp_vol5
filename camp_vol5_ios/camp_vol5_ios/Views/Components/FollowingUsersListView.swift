// Views/Components/FollowingUsersListView.swift
// フォローユーザー一覧表示コンポーネント - ユーザーカードのリスト表示を担当
// SwiftUIベストプラクティスに従い、アクションを外部に委譲

import SwiftUI

struct FollowingUsersListView: View {
    let users: [UserWithHeartbeat]
    let backgroundImageManagers: [String: BackgroundImageManager]
    let onUserTapped: (UserWithHeartbeat) -> Void
    let onRefresh: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: CardConstants.cardVerticalSpacing) {
                ForEach(users, id: \.user.id) { userWithHeartbeat in
                    UserHeartbeatCardWrapper(
                        userWithHeartbeat: userWithHeartbeat,
                        backgroundImageManager: backgroundImageManagers[userWithHeartbeat.user.id]
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print(
                            "Tapping card for user: \(userWithHeartbeat.user.name), id: \(userWithHeartbeat.user.id)"
                        )
                        print(
                            "Background image for \(userWithHeartbeat.user.id): \(backgroundImageManagers[userWithHeartbeat.user.id]?.currentEditedImage != nil ? "present" : "nil")"
                        )
                        onUserTapped(userWithHeartbeat)
                    }
                    .id("card-\(userWithHeartbeat.user.id)")
                }
            }
            .padding(.top, 20)
        }
        .refreshable {
            onRefresh()
        }
    }
}

#Preview {
    FollowingUsersListView(
        users: [],
        backgroundImageManagers: [:],
        onUserTapped: { _ in },
        onRefresh: {}
    )
}

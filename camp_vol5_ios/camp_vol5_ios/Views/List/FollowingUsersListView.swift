// Views/List/FollowingUsersListView.swift
// フォローユーザー一覧表示コンポーネント - ユーザーカードのリスト表示を担当
// SwiftUIベストプラクティスに従い、アクションを外部に委譲

import SwiftUI

struct FollowingUsersListView: View {
    let users: [UserWithHeartbeat]
    let isEditMode: Bool
    let onUserTapped: (UserWithHeartbeat) -> Void
    let onRefresh: () -> Void
    let onUnfollow: ((String) -> Void)?
    let onToggleNotification: ((String, Bool) -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: CardConstants.cardVerticalSpacing) {
                ForEach(users, id: \.user.id) { userWithHeartbeat in
                    ZStack(alignment: .topLeading) {
                        UserHeartbeatCard(
                            userWithHeartbeat: userWithHeartbeat,
                            backgroundImageManager: userWithHeartbeat.backgroundImageManager
                        )
                        .contentShape(Rectangle())
                        .allowsHitTesting(!isEditMode)
                        .onTapGesture {
                            print(
                                "Tapping card for user: \(userWithHeartbeat.user.name), id: \(userWithHeartbeat.user.id)"
                            )
                            let hasImage =
                                userWithHeartbeat.backgroundImageManager?.currentEditedImage != nil
                            print(
                                "Background image for \(userWithHeartbeat.user.id): \(hasImage ? "present" : "nil")"
                            )
                            onUserTapped(userWithHeartbeat)
                        }

                        // 編集モード時のバツボタン（カードの左上に配置）
                        if isEditMode {
                            Button {
                                print("🔥 Unfollowing user: \(userWithHeartbeat.user.id)")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    onUnfollow?(userWithHeartbeat.user.id)
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 30, height: 30)

                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 20, y: 10)
                            .zIndex(1)
                            .scaleEffect(1.0)
                        }

                        // 編集モード時の通知トグルスイッチ（カードの右上に配置）
                        if isEditMode {
                            HStack {
                                Spacer()
                                Button {
                                    onToggleNotification?(
                                        userWithHeartbeat.user.id,
                                        !userWithHeartbeat.notificationEnabled
                                    )
                                } label: {
                                    Image(
                                        systemName: userWithHeartbeat.notificationEnabled
                                            ? "bell.fill" : "bell.slash.fill"
                                    )
                                    .foregroundColor(
                                        userWithHeartbeat.notificationEnabled ? .main : .gray
                                    )
                                    .padding(8)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                                }
                            }
                            .offset(x: -20, y: 10)
                            .zIndex(1)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .padding(.top, CardConstants.cardVerticalSpacing)
        }
        .refreshable {
            onRefresh()
        }
    }
}

#Preview {
    FollowingUsersListView(
        users: [],
        isEditMode: false,
        onUserTapped: { _ in },
        onRefresh: {},
        onUnfollow: { _ in },
        onToggleNotification: { _, _ in }
    )
}

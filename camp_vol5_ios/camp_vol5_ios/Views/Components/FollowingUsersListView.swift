// Views/Components/FollowingUsersListView.swift
// フォローユーザー一覧表示コンポーネント - ユーザーカードのリスト表示を担当
// SwiftUIベストプラクティスに従い、アクションを外部に委譲

import SwiftUI

struct FollowingUsersListView: View {
    let users: [UserWithHeartbeat]
    @ObservedObject var backgroundImageCoordinator: BackgroundImageCoordinator
    let isEditMode: Bool
    let onUserTapped: (UserWithHeartbeat) -> Void
    let onRefresh: () -> Void
    let onUnfollow: ((String) -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: CardConstants.cardVerticalSpacing) {
                ForEach(users, id: \.user.id) { userWithHeartbeat in
                    ZStack(alignment: .topLeading) {
                        UserHeartbeatCard(
                            userWithHeartbeat: userWithHeartbeat,
                            customBackgroundImage:
                                backgroundImageCoordinator.backgroundImageManagers[
                                    userWithHeartbeat.user.id]?.currentEditedImage
                        )
                        .contentShape(Rectangle())
                        .allowsHitTesting(!isEditMode)
                        .onTapGesture {
                            print(
                                "Tapping card for user: \(userWithHeartbeat.user.name), id: \(userWithHeartbeat.user.id)"
                            )
                            print(
                                "Background image for \(userWithHeartbeat.user.id): \(backgroundImageCoordinator.backgroundImageManagers[userWithHeartbeat.user.id]?.currentEditedImage != nil ? "present" : "nil")"
                            )
                            onUserTapped(userWithHeartbeat)
                        }

                        // 編集モード時のバツボタン（カードの上に配置）
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
                            // .transition(.scale(scale: 0.1))
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
        backgroundImageCoordinator: BackgroundImageCoordinator(),
        isEditMode: false,
        onUserTapped: { _ in },
        onRefresh: {},
        onUnfollow: { _ in }
    )
}

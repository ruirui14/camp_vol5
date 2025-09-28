// Views/Components/EmptyFollowingUsersView.swift
// フォローユーザーが空の場合の表示コンポーネント - ユーザー追加を促すUI
// SwiftUIベストプラクティスに従い、アクションを外部に委譲

import SwiftUI

struct EmptyFollowingUsersView: View {
    let onAddUser: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .padding(.bottom, 10)

                    Text("フォロー中のユーザーがいません")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)

                    Text("QRコードスキャンでユーザーを追加してみましょう")
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 20)

                    Button("ユーザーを追加") {
                        onAddUser()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
                .contentShape(Rectangle())
            }
            .refreshable {
                onRefresh()
            }
        }
    }
}

#Preview {
    EmptyFollowingUsersView(
        onAddUser: {},
        onRefresh: {}
    )
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
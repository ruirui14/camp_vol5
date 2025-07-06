// UserHeartbeatCard.swift
// フォローユーザーの心拍数情報を表示するカードコンポーネント
// NavigationLinkの中で使用されるリスト項目として設計

import SwiftUI

struct UserHeartbeatCard: View {
    let userWithHeartbeat: UserWithHeartbeat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(userWithHeartbeat.user.imageName ?? "detail_pic")
                .resizable()
                .scaledToFill()
                .frame(width: 370, height: 120)
                .clipped()
                .cornerRadius(20)

            HStack(spacing: 8) {
                Image("heart_beat")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .offset(x: 290, y: -36)

                Text(userWithHeartbeat.user.name)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: "#F6F6F8"))
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: -50, y: -48)
            }
            .padding()
        }
        .frame(width: 370, height: 120)
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 20) {
        // データありのカード
        UserHeartbeatCard(
            userWithHeartbeat: UserWithHeartbeat(
                user: User(
                    id: "user1",
                    name: "たろう",
                    imageName: "taro"
                ),
                heartbeat: Heartbeat(
                    userId: "user1",
                    bpm: 72
                )
            ))

        // 異なる画像のカード
        UserHeartbeatCard(
            userWithHeartbeat: UserWithHeartbeat(
                user: User(
                    id: "user2",
                    name: "あやか",
                    imageName: "ayuna_small"
                ),
                heartbeat: Heartbeat(
                    userId: "user2",
                    bpm: 85
                )
            ))

        // データなしのカード
        UserHeartbeatCard(
            userWithHeartbeat: UserWithHeartbeat(
                user: User(
                    id: "user3",
                    name: "るい",
                    imageName: "taro"
                ),
                heartbeat: nil
            ))
    }
    .padding()
}

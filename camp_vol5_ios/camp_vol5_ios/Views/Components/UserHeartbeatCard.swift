// UserHeartbeatCard.swift
// フォローユーザーの心拍数情報を表示するカードコンポーネント
// NavigationLinkの中で使用されるリスト項目として設計
// 背景画像カスタマイズ対応

import SwiftUI

struct UserHeartbeatCard: View {
    let userWithHeartbeat: UserWithHeartbeat?
    let customBackgroundImage: UIImage?
    let displayName: String?
    let displayBPM: String?
    
    // 既存のイニシャライザー（後方互換性のため）
    init(userWithHeartbeat: UserWithHeartbeat) {
        self.userWithHeartbeat = userWithHeartbeat
        self.customBackgroundImage = nil
        self.displayName = nil
        self.displayBPM = nil
    }
    
    // 新しいイニシャライザー（カスタマイズ用）
    init(userWithHeartbeat: UserWithHeartbeat? = nil,
         customBackgroundImage: UIImage? = nil,
         displayName: String? = nil,
         displayBPM: String? = nil) {
        self.userWithHeartbeat = userWithHeartbeat
        self.customBackgroundImage = customBackgroundImage
        self.displayName = displayName
        self.displayBPM = displayBPM
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景画像の表示
            if let customImage = customBackgroundImage {
                Image(uiImage: customImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 370, height: 120)
                    .clipped()
                    .cornerRadius(20)
            } else {
                // カード背景色（画像がない場合）
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 370, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 2)
                    )
            }

            HStack(spacing: 8) {
                ZStack {
                    Image("heart_beat")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    
                    if let bpm = displayBPM {
                        Text(bpm)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                    } else if let heartbeat = userWithHeartbeat?.heartbeat {
                        Text("\(heartbeat.bpm)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                }
                .offset(x: 290, y: -36)

                Text(displayName ?? userWithHeartbeat?.user.name ?? "プレビュー")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.base)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: -50, y: -48)
            }
            .padding()
        }
        .frame(width: 370, height: 120)
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

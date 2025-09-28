// UserHeartbeatCard.swift
// フォローユーザーの心拍数情報を表示するカードコンポーネント
// NavigationLinkの中で使用されるリスト項目として設計
// 背景画像カスタマイズ対応

import SwiftUI

struct UserHeartbeatCard: View {
    @StateObject private var viewModel: UserHeartbeatCardViewModel
    let customBackgroundImage: UIImage?

    // 新しいイニシャライザー（カスタマイズ用）
    init(
        userWithHeartbeat: UserWithHeartbeat? = nil,
        customBackgroundImage: UIImage? = nil,
        displayName: String? = nil,
        displayBPM: String? = nil
    ) {
        self.customBackgroundImage = customBackgroundImage

        if let userWithHeartbeat = userWithHeartbeat {
            self._viewModel = StateObject(
                wrappedValue: UserHeartbeatCardViewModel(
                    userWithHeartbeat: userWithHeartbeat,
                    customBackgroundImage: customBackgroundImage))
        } else {
            self._viewModel = StateObject(
                wrappedValue: UserHeartbeatCardViewModel(
                    customBackgroundImage: customBackgroundImage, displayName: displayName,
                    displayBPM: displayBPM))
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = CardConstants.cardWidth(for: geometry.size.width)
            let heartRightOffset = CardConstants.heartRightOffset(for: cardWidth)

            ZStack(alignment: .bottomLeading) {
                // 背景画像の表示（customBackgroundImageを直接使用）
                if let customImage = customBackgroundImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: CardConstants.cardHeight)
                        .clipped()
                        .cornerRadius(CardConstants.cornerRadius)
                } else {
                    // カード背景色（画像がない場合）
                    RoundedRectangle(cornerRadius: CardConstants.cornerRadius)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: cardWidth, height: CardConstants.cardHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: CardConstants.cornerRadius)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }

                // 心拍数表示（右上）
                ZStack {
                    Image("heart_beat")
                        .resizable()
                        .scaledToFill()
                        .frame(width: CardConstants.heartSize, height: CardConstants.heartSize)
                        .clipShape(Circle())

                    if !viewModel.displayBPM.isEmpty {
                        Text(viewModel.displayBPM)
                            .font(
                                .system(
                                    size: CardConstants.heartFontSize, weight: .heavy,
                                    design: .rounded)
                            )
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                }
                .offset(x: heartRightOffset, y: -CardConstants.heartBottomMargin)

                // ユーザー名（左下）
                Text(viewModel.displayName)
                    .font(.system(size: CardConstants.nameFontSize(for: cardWidth), weight: .bold))
                    .foregroundColor(.base)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: CardConstants.nameLeftMargin, y: -CardConstants.nameBottomMargin)
            }
            .frame(width: cardWidth, height: CardConstants.cardHeight)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: CardConstants.cardHeight)
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
            )
        )

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
            )
        )

        // データなしのカード
        UserHeartbeatCard(
            userWithHeartbeat: UserWithHeartbeat(
                user: User(
                    id: "user3",
                    name: "るい",
                    imageName: "taro"
                ),
                heartbeat: nil
            )
        )
    }
    .padding()
}

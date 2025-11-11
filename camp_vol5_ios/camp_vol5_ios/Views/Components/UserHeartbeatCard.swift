// UserHeartbeatCard.swift
// フォローユーザーの心拍数情報を表示するカードコンポーネント
// NavigationLinkの中で使用されるリスト項目として設計
// 背景画像カスタマイズ対応

import SwiftUI

struct UserHeartbeatCard: View {
    let userWithHeartbeat: UserWithHeartbeat?
    let backgroundImageManager: BackgroundImageManager?
    let customBackgroundImage: UIImage?
    let displayName: String?
    let displayBPM: String?

    init(
        userWithHeartbeat: UserWithHeartbeat? = nil,
        backgroundImageManager: BackgroundImageManager? = nil,
        customBackgroundImage: UIImage? = nil,
        displayName: String? = nil,
        displayBPM: String? = nil
    ) {
        self.userWithHeartbeat = userWithHeartbeat
        self.backgroundImageManager = backgroundImageManager
        self.customBackgroundImage = customBackgroundImage
        self.displayName = displayName
        self.displayBPM = displayBPM
    }

    var body: some View {
        if let manager = backgroundImageManager {
            // BackgroundImageManagerがある場合は@ObservedObjectで監視
            UserHeartbeatCardWithObservedManager(
                userWithHeartbeat: userWithHeartbeat,
                backgroundImageManager: manager,
                customBackgroundImage: customBackgroundImage,
                displayName: displayName,
                displayBPM: displayBPM
            )
        } else {
            // BackgroundImageManagerがない場合は直接表示
            UserHeartbeatCardContent(
                userWithHeartbeat: userWithHeartbeat,
                backgroundImage: customBackgroundImage,
                displayName: displayName,
                displayBPM: displayBPM
            )
        }
    }
}

// BackgroundImageManagerを@ObservedObjectとして監視する内部ビュー
private struct UserHeartbeatCardWithObservedManager: View {
    let userWithHeartbeat: UserWithHeartbeat?
    @ObservedObject var backgroundImageManager: BackgroundImageManager
    let customBackgroundImage: UIImage?
    let displayName: String?
    let displayBPM: String?

    var body: some View {
        UserHeartbeatCardContent(
            userWithHeartbeat: userWithHeartbeat,
            backgroundImage: backgroundImageManager.currentEditedImage ?? customBackgroundImage,
            displayName: displayName,
            displayBPM: displayBPM
        )
    }
}

// カードの実際のUI実装
private struct UserHeartbeatCardContent: View {
    @StateObject private var viewModel: UserHeartbeatCardViewModel
    let backgroundImage: UIImage?

    init(
        userWithHeartbeat: UserWithHeartbeat?,
        backgroundImage: UIImage?,
        displayName: String?,
        displayBPM: String?
    ) {
        self.backgroundImage = backgroundImage

        if let userWithHeartbeat = userWithHeartbeat {
            self._viewModel = StateObject(
                wrappedValue: UserHeartbeatCardViewModel(
                    userWithHeartbeat: userWithHeartbeat,
                    customBackgroundImage: backgroundImage))
        } else {
            self._viewModel = StateObject(
                wrappedValue: UserHeartbeatCardViewModel(
                    customBackgroundImage: backgroundImage,
                    displayName: displayName,
                    displayBPM: displayBPM
                )
            )
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = CardConstants.cardWidth(for: geometry.size.width)
            let heartRightOffset = CardConstants.heartRightOffset(for: cardWidth)

            ZStack(alignment: .bottomLeading) {
                // 背景画像の表示
                if let backgroundImage = backgroundImage {
                    Image(uiImage: backgroundImage)
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
                                    size: CardConstants.heartFontSize,
                                    weight: .heavy,
                                    design: .rounded
                                )
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
                    inviteCode: "code1",
                    allowQRRegistration: false
                ),
                heartbeat: Heartbeat(
                    userId: "user1",
                    bpm: 72
                ),
                notificationEnabled: true
            )
        )

        // 異なる画像のカード
        UserHeartbeatCard(
            userWithHeartbeat: UserWithHeartbeat(
                user: User(
                    id: "user2",
                    name: "あやか",
                    inviteCode: "code2",
                    allowQRRegistration: false
                ),
                heartbeat: Heartbeat(
                    userId: "user2",
                    bpm: 85
                ),
                notificationEnabled: true
            )
        )

        // データなしのカード
        UserHeartbeatCard(
            userWithHeartbeat: UserWithHeartbeat(
                user: User(
                    id: "user3",
                    name: "るい",
                    inviteCode: "code3",
                    allowQRRegistration: false
                ),
                heartbeat: nil,
                notificationEnabled: false
            )
        )
    }
    .padding()
}

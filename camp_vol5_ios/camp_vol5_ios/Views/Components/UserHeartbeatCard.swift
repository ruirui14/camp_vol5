// UserHeartbeatCard.swift
// フォローユーザーの心拍数情報を表示するカードコンポーネント
// NavigationLinkの中で使用されるリスト項目として設計
// 背景画像カスタマイズ対応（GIF対応）

import SDWebImageSwiftUI
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
            // BackgroundImageManagerがある場合は@ObservedObjectで監視（GIF対応）
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
                backgroundImageData: nil,
                isAnimated: false,
                displayName: displayName,
                displayBPM: displayBPM
            )
        }
    }
}

// BackgroundImageManagerを@ObservedObjectとして監視する内部ビュー（GIF対応）
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
            backgroundImageData: backgroundImageManager.currentImageData,
            isAnimated: backgroundImageManager.isAnimated,
            transform: backgroundImageManager.isAnimated
                ? backgroundImageManager.currentTransform : nil,
            displayName: displayName,
            displayBPM: displayBPM
        )
    }
}

// カードの実際のUI実装（GIF対応）
private struct UserHeartbeatCardContent: View {
    @StateObject private var viewModel: UserHeartbeatCardViewModel
    @State private var isAnimating = false
    let backgroundImage: UIImage?
    let backgroundImageData: Data?
    let isAnimated: Bool
    let transform: ImageTransform?

    init(
        userWithHeartbeat: UserWithHeartbeat?,
        backgroundImage: UIImage?,
        backgroundImageData: Data?,
        isAnimated: Bool,
        transform: ImageTransform? = nil,
        displayName: String?,
        displayBPM: String?
    ) {
        self.backgroundImage = backgroundImage
        self.backgroundImageData = backgroundImageData
        self.isAnimated = isAnimated
        self.transform = transform

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

    // ローディング状態かどうかを判定
    private var isLoading: Bool {
        viewModel.displayName.isEmpty
    }

    var body: some View {
        // GeometryReaderの使用を最小化: padding-basedレイアウトを採用
        ZStack(alignment: .bottomLeading) {
            // 背景画像の表示（GIF・静止画対応）
            backgroundView()

            // 心拍数表示（右上）
            ZStack {
                if isLoading {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: CardConstants.heartSize, height: CardConstants.heartSize)
                        .shimmer(isAnimating: isAnimating)
                } else {
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
            }
            .frame(width: CardConstants.heartSize, height: CardConstants.heartSize)
            .offset(y: -CardConstants.heartBottomMargin)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, CardConstants.heartRightMargin)

            // ユーザー名（左下）
            if isLoading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 120, height: 32)
                    .shimmer(isAnimating: isAnimating)
                    .padding(.leading, CardConstants.nameLeftMargin)
                    .padding(.bottom, CardConstants.nameBottomMargin)
            } else {
                Text(viewModel.displayName)
                    .font(.system(size: CardConstants.nameFontSizeBase, weight: .bold))
                    .foregroundColor(.base)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.leading, CardConstants.nameLeftMargin)
                    .padding(.bottom, CardConstants.nameBottomMargin)
            }
        }
        .frame(height: CardConstants.cardHeight)
        .padding(.horizontal, CardConstants.cardHorizontalMargin)
        .onAppear {
            isAnimating = true
        }
    }

    /// 背景画像ビューを生成（GIF・静止画・背景色対応）
    @ViewBuilder
    private func backgroundView() -> some View {
        if let imageData = backgroundImageData, isAnimated, let transform = transform {
            // GIFアニメーション（transform適用）
            animatedGifBackgroundView(imageData: imageData, transform: transform)
        } else if let imageData = backgroundImageData, isAnimated {
            // GIFアニメーション（transformなし）
            simpleAnimatedGifView(imageData: imageData)
        } else if let backgroundImage = backgroundImage {
            // 静止画像（背景色は既に含まれている）
            staticImageView(image: backgroundImage)
        } else {
            // デフォルト背景色
            defaultBackgroundView()
        }
    }

    /// GIF背景（transform適用）
    private func animatedGifBackgroundView(
        imageData: Data, transform: ImageTransform
    ) -> some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色
                if let bgColor = transform.backgroundColor {
                    RoundedRectangle(cornerRadius: CardConstants.cornerRadius)
                        .fill(Color(bgColor))
                }

                // GIF画像（パフォーマンス最適化設定）
                AnimatedImage(data: imageData)
                    .resizable()
                    .playbackRate(1.0)  // 再生速度を標準に設定
                    .playbackMode(.normal)  // 通常再生モード
                    .scaledToFit()
                    .frame(width: geometry.size.width * 2, height: CardConstants.cardHeight * 2)
                    .scaleEffect(transform.scale)
                    .rotationEffect(Angle(degrees: transform.rotation))
                    .offset(
                        x: transform.normalizedOffset.x * UIScreen.main.bounds.width,
                        y: transform.normalizedOffset.y * UIScreen.main.bounds.height
                    )
                    .frame(width: geometry.size.width, height: CardConstants.cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: CardConstants.cornerRadius))
            }
        }
        .frame(height: CardConstants.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: CardConstants.cornerRadius))
    }

    /// シンプルGIF背景（transformなし）
    private func simpleAnimatedGifView(imageData: Data) -> some View {
        AnimatedImage(data: imageData)
            .resizable()
            .playbackRate(1.0)  // 再生速度を標準に設定
            .playbackMode(.normal)  // 通常再生モード
            .scaledToFill()
            .frame(height: CardConstants.cardHeight)
            .clipped()
            .cornerRadius(CardConstants.cornerRadius)
    }

    /// 静止画像背景
    private func staticImageView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: CardConstants.cardHeight)
            .clipped()
            .cornerRadius(CardConstants.cornerRadius)
    }

    /// デフォルト背景色
    private func defaultBackgroundView() -> some View {
        RoundedRectangle(cornerRadius: CardConstants.cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .frame(height: CardConstants.cardHeight)
            .overlay(
                RoundedRectangle(cornerRadius: CardConstants.cornerRadius)
                    .stroke(Color.white, lineWidth: 2)
            )
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

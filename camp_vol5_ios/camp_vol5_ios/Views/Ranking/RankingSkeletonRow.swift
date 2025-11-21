// Views/Ranking/RankingSkeletonRow.swift
// ランキング読み込み中のスケルトン表示コンポーネント
// ランキング行のレイアウトに合わせたプレースホルダーを表示

import SwiftUI

struct RankingSkeletonRow: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 16) {
            // ランク表示のスケルトン
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .shimmer(isAnimating: isAnimating)

            // ユーザー情報のスケルトン
            VStack(alignment: .leading, spacing: 8) {
                // ユーザー名
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 20)
                    .shimmer(isAnimating: isAnimating)

                // 接続数
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 16)
                    .shimmer(isAnimating: isAnimating)

                // 日時
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 12)
                    .shimmer(isAnimating: isAnimating)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Shimmer Effect Modifier

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

struct ShimmerModifier: ViewModifier {
    let isAnimating: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear,
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                }
            )
            .mask(content)
            .onAppear {
                if isAnimating {
                    withAnimation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
            }
    }
}

// MARK: - Skeleton List View

struct RankingSkeletonList: View {
    let count: Int = 10

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<count, id: \.self) { _ in
                    RankingSkeletonRow()
                }
            }
            .padding()
        }
    }
}

#Preview("Skeleton Row") {
    RankingSkeletonRow()
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Skeleton List") {
    RankingSkeletonList()
        .background(Color(.systemGroupedBackground))
}

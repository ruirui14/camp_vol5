//
//  ImageEditView.swift
//  camp_vol5_ios
//
//  シンプルな画像編集ビュー
//

import SwiftUI

struct ImageEditView: View {
    @Binding var image: UIImage?
    @Binding var imageOffset: CGSize
    @Binding var imageScale: CGFloat
    let onApply: () -> Void
    @State private var tempOffset = CGSize.zero
    @State private var tempScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                // 黒い背景
                Color.black
                    .ignoresSafeArea()

                // 画像表示とジェスチャー
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(tempScale)
                        .offset(tempOffset)
                        .gesture(
                            SimultaneousGesture(
                                // ドラッグジェスチャー
                                DragGesture()
                                    .onChanged { value in
                                        tempOffset = value.translation
                                    },
                                // ズームジェスチャー
                                MagnificationGesture()
                                    .onChanged { value in
                                        tempScale = lastScale * value
                                    }
                                    .onEnded { value in
                                        lastScale = tempScale
                                        // 最小・最大スケールの制限
                                        if tempScale < 0.5 {
                                            tempScale = 0.5
                                            lastScale = 0.5
                                        } else if tempScale > 5.0 {
                                            tempScale = 5.0
                                            lastScale = 5.0
                                        }
                                    }
                            )
                        )
                }

                // ハートビート表示エリア（プレビュー用）
                VStack(spacing: 20) {
                    Spacer()
                    Spacer()
                    Spacer()
                    VStack(spacing: 8) {
                        ZStack {
                            Image("heart_beat")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 105, height: 92)
                                .clipShape(Circle())
                            Text("--")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        }

                        Text("プレビュー")
                            .font(.caption)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                    }
                    Spacer()
                }
                .padding()
                .padding(.top, 118)
            }
            .whiteCapsuleTitle("画像を編集")
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            // 透明なナビゲーションバーの設定
            .navigationBarBackgroundTransparent()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("適用") {
                        // 編集内容を適用
                        imageOffset = tempOffset
                        imageScale = tempScale
                        onApply()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // 現在の状態を編集画面に反映
            tempOffset = imageOffset
            tempScale = imageScale
            lastScale = imageScale
        }
    }
}

#Preview {
    ImageEditView(
        image: .constant(UIImage(systemName: "photo")),
        imageOffset: .constant(CGSize.zero),
        imageScale: .constant(1.0),
        onApply: {}
    )
}

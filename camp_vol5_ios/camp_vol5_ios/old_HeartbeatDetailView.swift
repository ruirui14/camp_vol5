//
//  detail_Card.swift
//  camp_vol5_ios
//
//  Created by rui on 2025/06/21.
//

import SwiftUI

struct old_HeartbeatDetailView: View {
  @Environment(\.dismiss) var dismiss
  let item: CardItem
  var body: some View {
    ZStack {
      // 背景グラデーション
      LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#FABDC2"), Color(hex: "#F35E6A")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      //            .frame(height: 800)
      .ignoresSafeArea()  // 全画面にグラデーション適用
      .zIndex(0)

      VStack(spacing: 0) {
        ZStack {
          HStack {
            Button(action: {
              // 左ボタンの処理
              dismiss()
            }) {
              Image("arrow_back_ios_new")
            }
            .offset(x: -100, y: -25)

            Text(item.name)
              .font(.system(size: 34, weight: .bold))
              .padding()
              .offset(x: -20, y: -25)
              .foregroundColor(.white)

          }
        }
        ZStack {
          Image(item.detailImageName)
            .resizable()
            .scaledToFill()
            .frame(width: 403, height: 666)
            .clipped()
            .offset(y: -25)

          Image("hukidashi")
            .resizable()
            .frame(width: 299, height: 131)
            .offset(x: 20, y: -255)

          Text("俺の心臓早いだろ？")
            .font(.system(size: 25, weight: .bold))
            .foregroundColor(Color(hex: "#444444"))
            .offset(x: 20, y: -263)
        }
      }

      Image(item.iconImageName)
        .resizable()
        .frame(width: 150, height: 150)
        .offset(y: 200)
        .zIndex(10)

      VStack {
        Spacer()
        CustomBottomBar()
        // .zIndex(999) // 最前面に出す
      }
      .zIndex(999)
    }
    .navigationBarBackButtonHidden(true)

  }
}

#Preview {
  old_ListHeartBeatsView()
}

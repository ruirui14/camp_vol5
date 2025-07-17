// Views/Components/WhiteCapsuleTitle.swift
// NavigationBarの位置に白い文字とカプセル背景のタイトルを表示するコンポーネント

import SwiftUI

struct WhiteCapsuleTitle: View {
    let title: String
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
            }
            .padding(.top, 52) // ステータスバー + NavigationBar分
            
            Spacer()
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}

extension View {
    func whiteCapsuleTitle(_ title: String) -> some View {
        self.overlay(WhiteCapsuleTitle(title: title))
    }
}
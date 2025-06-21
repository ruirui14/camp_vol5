
import SwiftUI

struct ContentView: View {
    
    let items: [CardItem] = [
        CardItem(name: "たろう", imageName: "taro", iconImageName: "heart_beat",detailImageName: "detail_pic"),
        CardItem(name: "るい", imageName: "taro", iconImageName: "heart_beat",detailImageName: "detail_pic"),
        CardItem(name: "あやか", imageName: "taro", iconImageName: "heart_beat",detailImageName: "detail_pic"),
        CardItem(name: "ドラえもん", imageName: "taro", iconImageName: "heart_beat",detailImageName: "detail_pic")
    ]
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#FABDC2"), Color(hex: "#F35E6A")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea() // 全画面にグラデーション適用
                
                
                VStack(spacing: 0) {
                    // カスタムナビゲーションバー
                    CustomNavigationBar(
                        title: "鼓動一覧",
                        height: 100,
                        backgroundColor: .white,
                        trailingButton:{
                            Button(action: {
                                print("QR tapped!")
                            }) {
                                Image("plusQR")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                        }
                    )
                    
                    // 👇 GeometryReaderで高さを取って、スクロールエリアを調整！
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(items) { item in
                                NavigationLink(destination: detail_Card(item: item)) {
                                    CardView(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 20)
                        
                    }
                }
                
                
                
                // 🔽 カスタムボトムバー
                CustomBottomBar()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            
        }
        .statusBar(hidden: true) // ステータスバー非表示
    }
}

//  カスタムナビゲーションバー（左寄せタイトル）
struct CustomNavigationBar<TrailingContent: View>: View {
    let title: String
    let height: CGFloat
    let backgroundColor: Color
    let trailingButton: () -> TrailingContent
    
    var body: some View {
        ZStack(alignment: .leading) {
            backgroundColor
                .ignoresSafeArea(edges: .top)
            
            HStack {
                
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.leading, 16)
                Spacer()
                
                trailingButton()
                    .padding(.trailing, 16)
            }
            .padding(.top, 20)
        }
        .frame(height: height)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// カスタムボトムバー
struct CustomBottomBar: View {
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                // 左ボタンの処理
            }) {
                Image("bottom_list_off")
            }
            Spacer()
            Spacer()
            Button(action: {
                // 右ボタンの処理
            }) {
                Image("setting_off")
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .shadow(color: .black.opacity(0.05), radius: 2, y: -1)
        
    }
}

//ぐラデーション
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}


// モデル
struct CardItem: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String   //カード用
    let iconImageName: String
    let detailImageName: String   // 詳細用
}

// カードビュー
struct CardView: View {
    let item: CardItem
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(item.imageName)   //カード（写真）のスタイル
                .resizable()
                .scaledToFill()
                .frame(width:370,height: 120)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(20)
                .padding(.horizontal, 15)
            
            //            LinearGradient(
            ////                gradient: Gradient(colors: [Color.black.opacity(0.3), .clear]),
            ////                startPoint: .bottom,
            //                endPoint: .top
            //            )
            //            .cornerRadius(20)
            
            HStack(spacing: 8) {
                Image(item.iconImageName)   //カード内心臓スタイル
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .offset(x:290,y: -36)   //無理やり位置変えた
                
                Text(item.name)     //カード内テキストのスタイル
                    .font(.system(size: 32,weight: .bold))
                    .foregroundColor(Color(hex: "#F6F6F8"))     //テキストの色
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)     //テキストの影ぼんやり黒
                    .offset(x: -50,y:-48)  //無理やり位置変えた
                
                
            }
            .padding()
        }
        //       .shadow(color: .black.opacity(0.15), radius: 5, y: 4)
    }
}



#Preview {
    ContentView()
}

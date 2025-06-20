////
////  ContentView.swift
////  camp_vol5_ios
////
////  Created by rui on 2025/06/19.
////
//
//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//
//            NavigationView{
//
//                Color.pink.opacity(0.1) //背景pink
//                    .ignoresSafeArea()  //画面全体に適用
//
//
//                    .toolbar {
//
//                        //トップバーカメラ表示ボタン
//                        ToolbarItem(placement: .navigationBarTrailing){
//                            Button(action: {
//                                //遷移するよ
//                            }) {
//                                Image("plusQR")
//                            }
//                        }
//                        //トップバーテキスト
//                        ToolbarItem(placement: .navigationBarLeading){
//                            Text("鼓動一覧")
//                                .font(.system(size: 37,weight: .bold))
//                                .offset(y:50)
//
//                        }
//
//
//
//                        //ボトムバー
//                        ToolbarItem(placement: .bottomBar){
//                            HStack {
//                                Spacer()
//                                Button(action: {
//                                    // 画面切り替え処理
//                                }) {
//                                    Image("bottom_list_off")
//                                }
//                                Spacer()
//                                Spacer()
//                                Button(action: {
//                                    //画面切り替え処理
//                                }) {
//                                    Image("setting_off")
//                                }
//                                Spacer()
//                            }
//
//                        }
//
//                    }
////                    .toolbarBackground(.white, for: .navigationBar)
////                    .toolbarBackground(.visible, for: .navigationBar)
////                    .navigationBarHidden(true)
//
////                    .toolbar{
////                        ToolbarItem {
////                            Button(action: {
////                                // 画面切り替え処理
////                            }) {
////                                Image("bottom_list_off")
////                            }
////                        }
////                    }
////                    .toolbarBackground(.gray, for: .tabBar)
//                // ボトムバーの背景を白に
//
//                    .toolbarBackground(Color.white, for: .bottomBar)
//                    .toolbarBackground(.visible, for: .bottomBar)
//
//            }
//            .ignoresSafeArea(edges: .top)
//            .statusBar(hidden: true) // 👈 ステータスバー非表示！
//
//        }
//
//
//}
//
//
//#Preview {
//    ContentView()
//}


//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Hello, World!")
//                    .padding()
//                Spacer()
//            }
//            .navigationBarHidden(true) // デフォルトのナビゲーションバーを非表示
//            .safeAreaInset(edge: .top) {
//                CustomNavigationBar(
//                    title: "Custom Navigation Bar",
//                    height: 100,
//                    backgroundColor: .blue,
//                    leadingButton: {
//                        Button("Button") {
//                            print("Left button tapped")
//                        }
//                        .foregroundColor(.white)
//                    }
//                )
//            }
//        }
//    }
//}
//
//// カスタムナビゲーションバーコンポーネント
//struct CustomNavigationBar<LeadingContent: View>: View {
//    let title: String
//    let height: CGFloat
//    let backgroundColor: Color
//    let leadingButton: () -> LeadingContent
//
//    var body: some View {
//        ZStack {
//            // 背景色
//            backgroundColor
//                .ignoresSafeArea(edges: .top)
//
//            HStack {
//                // 左側のボタン
//                leadingButton()
//                    .padding(.leading, 16)
//
//                Spacer()
//
//                // タイトル
//                Text(title)
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .fontWeight(.semibold)
//
//                Spacer()
//
//                // 右側のスペース（バランスを取るため）
//                Color.clear
//                    .frame(width: 60)
//            }
//            .padding(.horizontal)
//        }
//        .frame(height: height)
//    }
//}
//
//// 別のアプローチ：NavigationViewの外観をカスタマイズ
//struct AlternativeContentView: View {
//    init() {
//        // NavigationBarの外観を設定
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithOpaqueBackground()
//        appearance.backgroundColor = UIColor.systemBlue
//        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
//        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
//
//        UINavigationBar.appearance().standardAppearance = appearance
//        UINavigationBar.appearance().compactAppearance = appearance
//        UINavigationBar.appearance().scrollEdgeAppearance = appearance
//    }
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Hello, World!")
//                    .padding()
//                Spacer()
//            }
//            .navigationTitle("Custom Navigation Bar")
//            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Button") {
//                        print("Button tapped")
//                    }
//                    .foregroundColor(.white)
//                }
//            }
//        }
//        .accentColor(.white) // ナビゲーションバーのアクセントカラーを設定
//    }
//}
//
//// より高度なカスタムナビゲーションバー
//struct AdvancedCustomNavigationBar: View {
//    let title: String
//    let height: CGFloat
//    let gradientColors: [Color]
//
//    var body: some View {
//        ZStack {
//            // グラデーション背景
//            LinearGradient(
//                gradient: Gradient(colors: gradientColors),
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea(edges: .top)
//
//            HStack {
//                Button(action: {
//                    print("Back button tapped")
//                }) {
//                    Image(systemName: "chevron.left")
//                        .foregroundColor(.white)
//                        .font(.system(size: 18, weight: .medium))
//                }
//                .padding(.leading, 16)
//
//                Spacer()
//
//                Text(title)
//                    .font(.title2)
//                    .foregroundColor(.white)
//                    .fontWeight(.bold)
//
//                Spacer()
//
//                Button(action: {
//                    print("Menu button tapped")
//                }) {
//                    Image(systemName: "ellipsis")
//                        .foregroundColor(.white)
//                        .font(.system(size: 18, weight: .medium))
//                }
//                .padding(.trailing, 16)
//            }
//        }
//        .frame(height: height)
//        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
//    }
//}
//
//// 使用例
//struct ExampleView: View {
//    var body: some View {
//        VStack(spacing: 0) {
//            AdvancedCustomNavigationBar(
//                title: "Advanced Bar",
//                height: 120,
//                gradientColors: [.purple, .blue, .cyan]
//            )
//
//            ScrollView {
//                VStack(spacing: 20) {
//                    ForEach(0..<20) { index in
//                        Text("Item \(index)")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.gray.opacity(0.1))
//                            .cornerRadius(8)
//                    }
//                }
//                .padding()
//            }
//        }
//        .ignoresSafeArea(edges: .top)
//    }
//}
//
//#Preview {
//    ContentView()
//}
import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.pink.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 🔼 カスタムナビゲーションバー
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
                
                Spacer()
                
                // 🟣 メインコンテンツ
                Text("こんにちは〜！")
                    .padding()
                
                Spacer()
                
                // 🔽 カスタムボトムバー
                CustomBottomBar()
            }
            
        }
        .statusBar(hidden: true) // ステータスバー非表示
    }
}

// 📌 カスタムナビゲーションバー（左寄せタイトル）
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

// 📌 カスタムボトムバー
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
        .padding(.vertical, 10)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .shadow(color: .black.opacity(0.05), radius: 2, y: -1)
    }
}


#Preview {
    ContentView()
}

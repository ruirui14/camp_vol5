//
//  ContentView.swift
//  camp_vol5_ios
//
//  Created by rui on 2025/06/19.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView{
            Text("Hellow")
                .toolbar {
                    //ボトムバー
                    ToolbarItem(placement: .bottomBar){
                        HStack {
                            Spacer()
                            Button("中央ボタン") {}
                            Spacer()
                            Spacer()
                            Button("右ボタン") {}
                            Spacer()
                        }
                        
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}

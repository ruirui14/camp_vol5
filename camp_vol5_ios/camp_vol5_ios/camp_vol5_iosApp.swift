//
//  camp_vol5_iosApp.swift
//  camp_vol5_ios
//
//  Created by rui on 2025/06/19.
//

import SwiftUI

@main
struct camp_vol5_iosApp: App {
    init() {
        FirebaseConfig.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ListHeartBeatsView()
        }
    }
}

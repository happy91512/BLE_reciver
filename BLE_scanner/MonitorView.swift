//
//  MonitorView.swift
//  BLE_scanner
//
//  Created by 邱泰銓 on 2024/4/15.
//

import SwiftUI

struct MonitorView: View {
    @State private var isLoginned = UserDefaults.standard.bool(forKey: "isLoggedIn")
    var body: some View {
        NavigationView {
            VStack {
                if isLoginned {
                    Text("History Page")
                } else {
                    Text("Please loggin first!")
                }
            }
        }
    }
}

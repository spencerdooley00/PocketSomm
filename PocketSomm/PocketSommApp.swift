//
//  PocketSommApp.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/27/25.
//  Modified to use a tab bar navigation.
//

import SwiftUI
import SwiftData

@main
struct PocketSommApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            // Use the MainTabView as the top level navigation structure.
            MainTabView()
                .environmentObject(appState)
        }
    }
}

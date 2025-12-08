//
//  PocketSommApp.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/27/25.
//


import SwiftUI
import SwiftData

@main
struct PocketSommApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootView()
            }
            .environmentObject(appState)
        }
    }
}


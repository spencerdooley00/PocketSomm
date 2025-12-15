//
//  MainTabView.swift
//  PocketSomm
//
//  Created as part of the production‑level navigation redesign.
//

import SwiftUI

/// The top‑level tab view used throughout the app. Each tab hosts its own
/// root view. Wrapping each in a ``TabView`` provides a more native
/// navigation structure than the previous single list. Additional tabs can
/// be added here as new features are developed.
struct MainTabView: View {
    var body: some View {
        TabView {
            // Home tab: hosts the existing RootView, which contains
            // navigation links to add wines, search, and the taste survey.
            RootView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            // Restaurant tools tab: shows menu recommendation tools. In the
            // future this could host other restaurant‑related utilities.
            MenuRecommendationsView()
                .tabItem {
                    Label("Menu", systemImage: "doc.text")
                }

            // Profile tab: displays the user's profile, favorites, tastings
            // and insights. The taste survey and account settings live here.
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

// Preview for Xcode canvas.
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppState())
    }
}

//
//  RootView.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/26/25.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 24) {
            NavigationStack {
                List {
                    Section("Add & search wines") {
                        NavigationLink("Add by photo") {
                            AddFavoriteFromPhotoView()
                        }
                        NavigationLink {
                            AddFavoriteByNameView()
                        } label: {
                            Text("Add by name")
                        }

                        NavigationLink("Search wines") {
                            WineSearchView()
                        }
                    }

                    Section("Restaurant tools") {
                        NavigationLink("Menu recommendations") {
                            MenuRecommendationsView()
                        }
                    }

                    Section("Profile") {
                        NavigationLink("Your profile") {
                            ProfileView()
                        }
                    }
                }
                .navigationTitle("PocketSomm")
            }

            NavigationLink("Taste Survey") {
                TasteSurveyView()
            }

           

            Spacer()
        }
        .padding()
        .navigationTitle("PocketSomm")
    }
}


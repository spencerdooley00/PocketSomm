//
//  ProfileView_updated.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/27/25.
//  Updated to apply PocketSomm design system styles.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                summaryCardLink

                if let survey = appState.userProfile?.surveyAnswers {
                    tasteProfileCard(survey)
                } else {
                    emptyTasteProfileCard
                }

                favoritesCard
                recommendationsPlaceholderCard
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Your Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await appState.loadUserProfile()
        }
    }

    // MARK: - Cards

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PocketSomm Profile")
                .font(.largeTitle.bold())

            Text("We use your saved wines and taste survey to learn what you like and surface better bottles over time.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .pocketCardStyle()
    }

    private var summaryCardLink: some View {
        NavigationLink {
            ProfileSummaryView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Taste summary")
                    .font(.headline)

                Text("See a breakdown of the grapes, regions, and styles you keep coming back to.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Keep plain style for navigation link but apply shared card style
        .buttonStyle(.plain)
        .pocketCardStyle()
    }

    private func tasteProfileCard(_ survey: TasteSurveyAnswers) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Taste snapshot")
                    .font(.headline)
                Spacer()
                Button {
                    // TODO: navigation back to survey editor
                } label: {
                    Text("Edit")
                        .font(.subheadline.weight(.semibold))
                }
            }

            if !survey.favoriteStyles.isEmpty {
                Text("Styles you enjoy")
                    .font(.subheadline.weight(.semibold))

                let columns = [
                    GridItem(.adaptive(minimum: 120), spacing: 8)
                ]

                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(survey.favoriteStyles, id: \.self) { style in
                        // Use TagChip from the design system for consistent styling
                        TagChip(text: styleLabel(style))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                profileLine(title: "Tannin", value: survey.tanninPref.capitalized)
                profileLine(title: "Acidity", value: survey.acidityPref.capitalized)
                profileLine(title: "Oak", value: survey.oakPref.capitalized)
                profileLine(title: "Adventure", value: survey.adventurePref.capitalized)
            }
            .font(.subheadline)
        }
        .pocketCardStyle()
    }

    private var emptyTasteProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set up your taste profile")
                .font(.headline)

            Text("Answer a few quick questions so we can anchor recommendations around what you actually like.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            NavigationLink {
                TasteSurveyView()
            } label: {
                Text("Start taste survey")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            // Apply primary button style for the call to action
            .buttonStyle(PrimaryButtonStyle())
        }
        .pocketCardStyle()
    }

    private var favoritesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorite wines")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    AddFavoriteFromPhotoView()
                } label: {
                    Label("Add by photo", systemImage: "camera.fill")
                        .font(.subheadline)
                }
                // Use plain button style for navigation links
                .buttonStyle(.plain)
            }

            if appState.isLoadingProfile {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading your wines…")
                        .font(.subheadline)
                }
            } else if let favorites = appState.userProfile?.favoriteWines,
                      !favorites.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(favorites.prefix(10)) { fav in
                        NavigationLink {
                            WineDetailView(wineId: fav.wineId)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fav.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(2)

                                    if let addedAt = fav.addedAt {
                                        Text("Added \(addedAt.prefix(10))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: fav.source == "photo" ? "camera.fill" : "text.quote")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)

                        if fav.id != favorites.prefix(10).last?.id {
                            Divider().opacity(0.3)
                        }
                    }
                }

            } else {
                Text("No wines saved yet. Add a bottle you liked and we’ll start learning your taste.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .pocketCardStyle()
    }

    private var recommendationsPlaceholderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)

            Text("Soon this will show bottles tailored to your profile, mixing survey preferences with the wines you’ve actually liked.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("For now, keep adding wines you enjoy and filling in your survey. That’s the fuel for the recommender.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .pocketCardStyle()
    }

    // MARK: - Helpers

    private func profileLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }

    private func styleLabel(_ raw: String) -> String {
        switch raw {
        case "light_fruity_red": return "Light & fruity reds"
        case "medium_red":      return "Medium reds"
        case "bold_red":        return "Bold reds"
        case "crisp_white":     return "Crisp whites"
        case "rich_white":      return "Richer whites"
        case "sparkling":       return "Sparkling"
        case "rose", "rosé":    return "Rosé"
        default:
            return raw.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}


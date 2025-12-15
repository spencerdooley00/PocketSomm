//
//  ProfileSummaryView_updated.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/29/25.
//  Updated to apply PocketSomm design system styles.
//

import SwiftUI

struct ProfileSummaryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                if let insights = appState.insights {
                    insightsCard(insights)
                } else if appState.isLoadingInsights {
                    loadingCard
                } else {
                    emptyCard
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .navigationTitle("Taste summary")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await appState.loadUserProfile()
            await appState.loadInsights()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What your wines say about you")
                .font(.title2.weight(.semibold))
            Text("This is a snapshot of your palate based on your taste survey and the bottles you’ve saved so far.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .pocketCardStyle()
    }

    private func insightsCard(_ insights: UserInsightsDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall summary")
                .font(.headline)
            Text(insights.summary)
                .font(.subheadline)
                .foregroundColor(.primary)
            Divider().padding(.vertical, 4)
            if !insights.topGrapes.isEmpty {
                Text("Grapes you gravitate to")
                    .font(.subheadline.weight(.semibold))
                chipWrap(insights.topGrapes)
            }
            if !insights.topCountries.isEmpty {
                Text("Favorite countries")
                    .font(.subheadline.weight(.semibold))
                chipWrap(insights.topCountries)
            }
            if !insights.topRegions.isEmpty {
                Text("Regions that keep showing up")
                    .font(.subheadline.weight(.semibold))
                chipWrap(insights.topRegions)
            }
            if !insights.topVintages.isEmpty {
                Text("Typical vintages")
                    .font(.subheadline.weight(.semibold))
                chipWrap(insights.topVintages.map { String($0) })
            }
        }
        .pocketCardStyle()
    }

    private var loadingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ProgressView()
                Text("Building your taste summary…")
                    .font(.subheadline)
            }
        }
        .pocketCardStyle()
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Not enough data yet")
                .font(.headline)
            Text("Add a few more wines you’ve loved and complete your taste survey so we can build a reliable profile.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .pocketCardStyle()
    }

    private func chipWrap(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                // Use TagChip from the design system to style chips consistently
                TagChip(text: item)
            }
        }
    }
}

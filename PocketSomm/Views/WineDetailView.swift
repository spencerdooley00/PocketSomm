//
//  WineDetailView.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/27/25.
//
import SwiftUI
import UIKit

struct WineDetailView: View {
    @EnvironmentObject var appState: AppState

    let wineId: String

    // Detail + similar
    @State private var wine: WineDetailDTO?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var similarWines: [SimilarWineDTO]? = nil

    // Tasting form
    @State private var rating: Double = 4.0
    @State private var contextText: String = ""
    @State private var notesText: String = ""
    @State private var isSavingTasting = false
    @State private var tastingSaveMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MAIN CONTENT
                if let wine = wine {
                    headerCard(wine)
                    metaCard(wine)
                    tastingFormCard()
                    pastTastingsCard()
                    similarWinesSection()
                } else if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading wine details…")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Text("Couldn’t load this wine.")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .navigationTitle("Wine")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadWine()
            await loadSimilarWines()
        }
    }

    // MARK: - Cards

    private func headerCard(_ wine: WineDetailDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            // ✅ local photo takes priority
            if let base64 = wine.imageBase64,
               let data = Data(base64Encoded: base64),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .cornerRadius(16)
            } else if let urlString = wine.imageURL,
                      let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 120)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .cornerRadius(16)
                    case .failure:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // ... existing name / producer / region stuff ...
            Text(wine.displayName)
                .font(.title2.weight(.semibold))
            // ...
        }
        .cardStyle()
    }




    private func metaCard(_ wine: WineDetailDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profile")
                .font(.headline)

            if let grapesLine = wine.grapesLine {
                profileRow(label: "Grapes", value: grapesLine)
            }

            if let country = wine.country {
                profileRow(label: "Country", value: country)
            }

            if let region = wine.region {
                profileRow(label: "Region", value: region)
            }

            if let appellation = wine.appellation, !appellation.isEmpty {
                profileRow(label: "Appellation", value: appellation)
            }

            if let text = wine.embeddingText, !text.isEmpty {
                Divider().padding(.vertical, 6)
                Text("Style summary")
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }

    private func tastingFormCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rate this wine")
                .font(.headline)

            HStack {
                Text("Rating")
                    .foregroundColor(.secondary)
                Spacer()
                Slider(value: $rating, in: 0...5, step: 0.5)
                    .frame(maxWidth: 180)
                Text(String(format: "%.1f", rating))
                    .font(.subheadline.monospacedDigit())
            }

            TextField("Occasion / context (optional)", text: $contextText)
                .textFieldStyle(.roundedBorder)

            TextField("Notes (optional)", text: $notesText, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)

            Button {
                Task {
                    await saveTasting()
                }
            } label: {
                if isSavingTasting {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                } else {
                    Text("Save tasting")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSavingTasting)

            if let msg = tastingSaveMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }

    private func pastTastingsCard() -> some View {
        guard let tastings = appState.userProfile?.tastings?
                .filter({ $0.wineId == wineId }),
              !tastings.isEmpty
        else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("Your tastings")
                    .font(.headline)

                ForEach(tastings.sorted(by: { ($0.timestamp ?? "") > ($1.timestamp ?? "") })) { t in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(String(format: "%.1f ★", t.rating))
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            if let ts = t.timestamp {
                                Text(String(ts.prefix(10)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        if let context = t.context, !context.isEmpty {
                            Text(context)
                                .font(.caption)
                        }
                        if let notes = t.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    if t.id != tastings.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            }
            .cardStyle()
        )
    }

    private func similarWinesSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Similar wines")
                .font(.headline)

            if let similar = similarWines {
                ForEach(similar) { item in
                    NavigationLink {
                        WineDetailView(wineId: item.wine_id)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline.bold())
                            if let region = item.region {
                                Text(region)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    if item.id != similar.last?.id {
                        Divider().opacity(0.3)
                    }
                }
            } else {
                Text("Loading…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .cardStyle()
    }

    // MARK: - Helpers

    private func profileRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func colorTagColor(_ color: String) -> Color {
        switch color.lowercased() {
        case "red": return .red.opacity(0.7)
        case "white": return .yellow.opacity(0.7)
        case "rosé", "rose": return .pink.opacity(0.7)
        case "sparkling": return .gray.opacity(0.6)
        default: return .secondary.opacity(0.6)
        }
    }

    private func colorDisplay(_ color: String) -> String {
        switch color.lowercased() {
        case "red": return "Red"
        case "white": return "White"
        case "rosé", "rose": return "Rosé"
        case "sparkling": return "Sparkling"
        default: return color.capitalized
        }
    }

    // MARK: - Loading

    private func loadWine() async {
        isLoading = true
        errorMessage = nil
        do {
            let detail = try await APIClient.shared.fetchWineDetail(wineId: wineId)
            await MainActor.run {
                self.wine = detail
            }
        } catch {
            await MainActor.run {
                if let apiError = error as? APIError {
                    self.errorMessage = apiError.localizedDescription
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        isLoading = false
    }

    private func loadSimilarWines() async {
        do {
            let similar = try await APIClient.shared.fetchSimilarWines(wineId: wineId)
            await MainActor.run {
                self.similarWines = similar
            }
        } catch {
            // Not critical enough to block the page; just log it
            print("Failed to load similar wines:", error)
        }
    }

    // MARK: - Tasting save

    private func saveTasting() async {
        guard !isSavingTasting else { return }
        isSavingTasting = true
        tastingSaveMessage = nil

        await appState.addTasting(
            wineId: wineId,
            rating: rating,
            context: contextText.isEmpty ? nil : contextText,
            notes: notesText.isEmpty ? nil : notesText
        )

        await MainActor.run {
            isSavingTasting = false
            tastingSaveMessage = "Saved."
            // Optionally clear:
            // contextText = ""
            // notesText = ""
        }
    }
}

// MARK: - Shared card style



private func placeholderBottle(color: String?) -> some View {
    let baseColor: Color
    switch color?.lowercased() {
    case "red":
        baseColor = .red
    case "white":
        baseColor = .yellow
    case "rosé", "rose":
        baseColor = .pink
    case "sparkling":
        baseColor = .gray
    default:
        baseColor = .secondary
    }

    return RoundedRectangle(cornerRadius: 8)
        .fill(baseColor.opacity(0.3))
        .frame(width: 80, height: 200)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(baseColor.opacity(0.6), lineWidth: 1.5)
        )
}

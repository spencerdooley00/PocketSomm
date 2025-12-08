//
//  WineSearchView.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/29/25.
//

import SwiftUI

struct WineSearchView: View {
    @EnvironmentObject var appState: AppState

    @State private var query: String = ""
    @State private var isSearching = false
    @State private var results: [WineSearchResultDTO] = []
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Search your wines")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Type part of a wine name, producer, or region. We’ll search wines we’ve already seen from your photos, menus, and favorites.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("e.g. “Nuits-Saint-Georges”", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await performSearch() }
                    }

                Button {
                    Task { await performSearch() }
                } label: {
                    if isSearching {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !results.isEmpty {
                List {
                    ForEach(results) { wine in
                        NavigationLink {
                            WineDetailView(wineId: wine.wineId)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(wine.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(2)

                                HStack(spacing: 6) {
                                    if let producer = wine.producer, !producer.isEmpty {
                                        Text(producer)
                                    }
//                                    if let region = wine.region, !region.isEmpty {
//                                        Text("• \(region)")
//                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            } else if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSearching {
                Text("No wines found matching “\(query)”")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
            } else {
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Search wines")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await MainActor.run {
            isSearching = true
            errorMessage = nil
        }

        do {
            let res = try await APIClient.shared.searchWines(query: trimmed)
            await MainActor.run {
                self.results = res
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            isSearching = false
        }
    }
}

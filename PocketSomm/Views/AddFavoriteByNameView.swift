//
//  AddFavoriteByNameView_updated.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/28/25.
//  Updated to integrate the PocketSomm design system without changing class names or methods.
//

import SwiftUI

/// This view allows a user to add a wine to their favourites by entering its name.
/// It has been updated to use the design system defined in `PocketSommTheme.swift`.
struct AddFavoriteByNameView: View {
    @EnvironmentObject var appState: AppState

    @State private var wineName: String = ""
    @State private var isResolving: Bool = false
    @State private var resolvedProfile: WineProfileDTO? = nil
    @State private var errorMessage: String? = nil
    @State private var isSaving: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                textInputSection

                if let profile = resolvedProfile {
                    confirmationCard(profile)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Add by name")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a wine you liked")
                .font(.title2.weight(.semibold))
            Text("Type the label or producer as you remember it. We’ll try to identify the bottle and add it to your favorites.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("e.g. “Lapierre Morgon 2021”", text: $wineName)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit {
                    Task { await resolve() }
                }

            Button {
                Task { await resolve() }
            } label: {
                HStack {
                    if isResolving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                        Text("Find this wine")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            // Use primary button style for the search action
            .buttonStyle(PrimaryButtonStyle())
            .disabled(wineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isResolving)
        }
    }

    private func confirmationCard(_ profile: WineProfileDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Is this your wine?")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text(profile.resolvedName ?? profile.inputName ?? "Unknown wine")
                    .font(.subheadline.weight(.semibold))
                if let producer = profile.producer, !producer.isEmpty {
                    Text(producer)
                        .font(.subheadline)
                }
                HStack(spacing: 6) {
                    if let region = profile.region, !region.isEmpty {
                        Text(region)
                    }
                    if let country = profile.country, !country.isEmpty {
                        Text("• \(country)")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if let grapes = profile.grapes, !grapes.isEmpty {
                    Text(grapes.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let style = profile.styleDescription, !style.isEmpty {
                    Divider().padding(.vertical, 4)
                    Text(style)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Button(role: .cancel) {
                    // Let them tweak the text and try again
                    resolvedProfile = nil
                } label: {
                    Text("Not quite")
                        .frame(maxWidth: .infinity)
                }
                // Keep a secondary style for the cancel action
                .buttonStyle(.bordered)

                Button {
                    Task { await confirm(profile) }
                } label: {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Looks right")
                            .frame(maxWidth: .infinity)
                    }
                }
                // Use primary style for the confirm action
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSaving)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        // Apply PocketSomm card styling from the design system instead of custom background and corner radius
        .pocketCardStyle()
    }

    // MARK: - Actions

    private func resolve() async {
        let trimmed = wineName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await MainActor.run {
            isResolving = true
            errorMessage = nil
            resolvedProfile = nil
        }

        do {
            let profile = try await APIClient.shared.resolveWineByName(name: trimmed)
            await MainActor.run {
                self.resolvedProfile = profile
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            isResolving = false
        }
    }

    private func confirm(_ profile: WineProfileDTO) async {
        guard !isSaving else { return }

        await MainActor.run {
            isSaving = true
            errorMessage = nil
        }

        do {
            // Adjust this depending on how you store userId
            let userId = appState.userId   // or hard-code "spencer" for now
            try await APIClient.shared.addFavoriteFromProfile(userId: userId, profile: profile)
            await appState.loadUserProfile()
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

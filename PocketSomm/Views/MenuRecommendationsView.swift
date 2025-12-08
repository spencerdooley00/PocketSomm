//
//  MenuRecommendationsView.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/28/25.
//
import SwiftUI
import UniformTypeIdentifiers

struct MenuRecommendationsView: View {
    @EnvironmentObject var appState: AppState

    @State private var isImporterPresented = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var recommendations: [MenuWineDTO] = []

    var body: some View {
        VStack(spacing: 24) {
            Text("Recommend from a restaurant menu")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Upload a PDF wine list and we’ll tell you which wines are most aligned with your taste profile.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                isImporterPresented = true
            } label: {
                HStack {
                    Image(systemName: "doc.richtext")
                    Text("Choose menu PDF")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Analyzing menu…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !recommendations.isEmpty {
                Divider().padding(.vertical, 4)

                Text("Top matches")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                List {
                    ForEach(recommendations) { item in
                        NavigationLink {
                            WineDetailView(wineId: item.wineId)
                        } label: {
                            Text(item.label)
                                .font(.subheadline)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            } else {
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Menu Recs")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .failure(let err):
            errorMessage = err.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                await uploadPdf(at: url)
            }
        }
    }

    private func uploadPdf(at url: URL) async {
        isLoading = true
        errorMessage = nil

        do {
            // IMPORTANT: security-scoped access
            let canAccess = url.startAccessingSecurityScopedResource()
            defer {
                if canAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // Now it's legal to read the file
            let data = try Data(contentsOf: url)
            let base64 = data.base64EncodedString()

            guard !appState.userId.isEmpty else {
                await MainActor.run {
                    self.errorMessage = "User not initialized."
                    self.isLoading = false
                }
                return
            }

            let recs = try await APIClient.shared.recommendFromMenuPdf(
                userId: appState.userId,
                pdfBase64: base64
            )

            await MainActor.run {
                self.recommendations = recs
            }

        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            self.isLoading = false
        }
    }

}


//
//  AddFavoritesFromPhotoView_updated.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/26/25.
//  Updated to apply PocketSomm design system styles.
//

import SwiftUI
import PhotosUI
import UIKit

struct AddFavoriteFromPhotoView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                if appState.showSuccessBanner {
                    successBanner
                }
                photoPickerSection
                photoPreviewSection
                statusSection
                if let profile = appState.lastWineProfile {
                    profileCard(profile)
                }
                Spacer(minLength: 24)
            }
            .padding(.horizontal)
            .padding(.top, 24)
        }
        .navigationTitle("Add by Photo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                Task {
                    await handlePickedImage(image)
                }
            }
        }
        .photosPicker(
            isPresented: $showPhotoLibrary,
            selection: $selectedItem,
            matching: .images
        )
        .onChange(of: selectedItem) { newItem in
            guard let item = newItem else { return }
            Task {
                await handlePickedItem(item)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a wine you liked")
                .font(.title2.weight(.semibold))
            Text("Snap or choose a photo of the bottle label. We’ll recognize it and add it to your favorites.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var successBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .imageScale(.large)
            Text("Wine saved to your favorites.")
                .font(.subheadline)
        }
        .foregroundColor(.green)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.green.opacity(0.12))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var photoPickerSection: some View {
        VStack(spacing: 12) {
            Button {
                showCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera")
                    Text("Take Photo")
                }
                .frame(maxWidth: .infinity)
            }
            // Apply primary button style
            .buttonStyle(PrimaryButtonStyle())
            .disabled(appState.isUploadingPhoto)

            Button {
                showPhotoLibrary = true
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text(selectedImageData == nil ? "Choose Photo" : "Choose Another Photo")
                }
                .frame(maxWidth: .infinity)
            }
            // Use primary button style to unify secondary action; overlay border is removed
            .buttonStyle(PrimaryButtonStyle())
            .disabled(appState.isUploadingPhoto)
        }
    }

    private var photoPreviewSection: some View {
        Group {
            if let data = selectedImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(radius: 4)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "wineglass.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No photo selected yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(Color.secondary.opacity(0.07))
                .cornerRadius(14)
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if appState.isUploadingPhoto {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Analyzing wine…")
                        .font(.subheadline)
                }
            } else if let error = appState.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            } else if selectedImageData == nil {
                Text("Tip: clear, straight-on label photos work best.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func profileCard(_ profile: WineProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(profile.resolvedName ?? "Unknown wine")
                .font(.headline)
            if let producer = profile.producer {
                Text(producer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 6) {
                if let region = profile.region {
                    Text(region)
                }
                if let country = profile.country {
                    Text("• \(country)")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            if let grapes = profile.grapes, !grapes.isEmpty {
                Text("Grapes: \(grapes.joined(separator: ", "))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            if let notes = profile.notes {
                Text(notes)
                    .font(.footnote)
                    .foregroundColor(.primary)
            }
            Button(role: .none) {
                selectedImageData = nil
                appState.resetCurrentPhotoFlow()
            } label: {
                Text("Add another wine")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            // Use primary button style for call to action
            .buttonStyle(PrimaryButtonStyle())
        }
        .pocketCardStyle()
    }

    // MARK: - Logic

    private func handlePickedItem(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    self.selectedImageData = data
                }
                await appState.addFavoriteFromPhoto(imageData: data)
            }
        } catch {
            await MainActor.run {
                appState.errorMessage = "Failed to load image: \(error.localizedDescription)"
            }
        }
    }
    private func handlePickedImage(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        await MainActor.run {
            self.selectedImageData = data
        }
        await appState.addFavoriteFromPhoto(imageData: data)
    }
}

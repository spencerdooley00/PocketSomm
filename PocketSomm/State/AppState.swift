//
//  AppState.swift
//  PocketSomm
//
//  Updated application state to integrate with the new API client and error types.
//  This version uses `APIClientEnvelope` instead of the old `APIClient` and
//  handles errors using `NetworkError` instead of the removed `APIError`.
//

import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var userId: String = "spencer"  // hard-coded for now
    @Published var lastWineProfile: WineProfile?
    @Published var isUploadingPhoto: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccessBanner: Bool = false
    @Published var lastSurveyAnswers: TasteSurveyAnswers = .default
    @Published var isSubmittingSurvey: Bool = false
    @Published var surveySaved: Bool = false
    @Published var userProfile: UserProfileDTO?
    @Published var isLoadingProfile: Bool = false
    @Published var insights: UserInsightsDTO?
    @Published var isLoadingInsights = false

    // MARK: - Insights
    func loadInsights() async {
        isLoadingInsights = true
        defer { isLoadingInsights = false }
        do {
            let data = try await APIClient.shared.fetchUserInsights(userId: userId)
            self.insights = data
        } catch {
            print("Failed to load insights:", error)
        }
    }

    // MARK: - Photo favorites
    func addFavoriteFromPhoto(imageData: Data) async {
        isUploadingPhoto = true
        errorMessage = nil
        showSuccessBanner = false
        do {
            let (profile, updatedUser) = try await APIClient.shared.addFavoriteFromPhoto(userId: userId, imageData: imageData)
            self.lastWineProfile = profile
            self.showSuccessBanner = true
            if let user = updatedUser {
                self.userProfile = user
                if let survey = user.surveyAnswers {
                    self.lastSurveyAnswers = survey
                }
            } else {
                print("⚠️ No 'user' in response")
            }
            // Hard-refresh from backend so everything stays in sync
            await loadUserProfile()
            await loadInsights()
        } catch {
            if let netError = error as? NetworkError {
                errorMessage = netError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isUploadingPhoto = false
    }

    func resetCurrentPhotoFlow() {
        lastWineProfile = nil
        errorMessage = nil
        showSuccessBanner = false
    }

    // MARK: - Survey
    func submitSurvey(answers: TasteSurveyAnswers) async {
        isSubmittingSurvey = true
        surveySaved = false
        errorMessage = nil
        do {
            let user = try await APIClient.shared.submitSurvey(userId: userId, answers: answers)
            self.lastSurveyAnswers = answers
            self.surveySaved = true
            self.userProfile = user
            await loadUserProfile()
            await loadInsights()
        } catch {
            if let netError = error as? NetworkError {
                errorMessage = netError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isSubmittingSurvey = false
    }

    // MARK: - Profile
    func loadUserProfile() async {
        isLoadingProfile = true
        errorMessage = nil
        do {
            let profile = try await APIClient.shared.fetchUserProfile(userId: userId)
            self.userProfile = profile
            if let survey = profile.surveyAnswers {
                self.lastSurveyAnswers = survey
            }
        } catch {
            if let netError = error as? NetworkError {
                errorMessage = netError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoadingProfile = false
    }

    // MARK: - Tastings
    func addTasting(wineId: String, rating: Double, context: String?, notes: String?) async {
        guard !userId.isEmpty else { return }
        do {
            let updatedUser = try await APIClient.shared.addTasting(userId: userId, wineId: wineId, rating: rating, context: context, notes: notes)
            self.userProfile = updatedUser
            if let survey = updatedUser.surveyAnswers {
                self.lastSurveyAnswers = survey
            }
            await loadUserProfile()
            await loadInsights()
        } catch {
            print("Failed to add tasting:", error)
        }
    }

    // MARK: - Favorites by text
    func addFavoriteByName(_ wineName: String) async {
        guard !userId.isEmpty else { return }
        do {
            let updated = try await APIClient.shared.addFavoriteByName(userId: userId, wineName: wineName)
            self.userProfile = updated
            if let survey = updated.surveyAnswers {
                self.lastSurveyAnswers = survey
            }
            await loadUserProfile()
            await loadInsights()
        } catch {
            print("Failed to add favorite by name:", error)
        }
    }
}

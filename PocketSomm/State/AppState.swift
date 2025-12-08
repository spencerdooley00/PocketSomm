//
//  AppState.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/26/25.
//


// AppState.swift
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
            let response = try await APIClient.shared.addFavoriteFromPhoto(
                userId: userId,
                imageData: imageData
            )

            self.lastWineProfile = response.wineProfile
            self.showSuccessBanner = true

            if let updatedUser = response.user {
                print("✅ Updated user from /favorite/from-photo:",
                      updatedUser.favoriteWines?.map(\.wineId) ?? [])
                self.userProfile = updatedUser

                if let survey = updatedUser.surveyAnswers {
                    self.lastSurveyAnswers = survey
                }
            } else {
                print("⚠️ No 'user' in response")
            }

            // Hard-refresh from backend so everything stays in sync
            await loadUserProfile()
            await loadInsights()
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.localizedDescription
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
            _ = try await APIClient.shared.submitSurvey(
                userId: userId,
                answers: answers
            )
            lastSurveyAnswers = answers
            surveySaved = true

            await loadUserProfile()
            await loadInsights()
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.localizedDescription
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
            userProfile = profile

            if let survey = profile.surveyAnswers {
                lastSurveyAnswers = survey
            }
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoadingProfile = false
    }

    // MARK: - Tastings

    func addTasting(
        wineId: String,
        rating: Double,
        context: String?,
        notes: String?
    ) async {
        guard !userId.isEmpty else { return }

        do {
            let updatedUser = try await APIClient.shared.addTasting(
                userId: userId,
                wineId: wineId,
                rating: rating,
                context: context,
                notes: notes
            )
            self.userProfile = updatedUser
            if let survey = updatedUser.surveyAnswers {
                self.lastSurveyAnswers = survey
            }

            await loadUserProfile()
            await loadInsights()
        } catch {
            print("Failed to add tasting:", error)
            // optional: hook into errorMessage if you want to show this
        }
    }

    // MARK: - Favorites by text

    func addFavoriteByName(_ wineName: String) async {
        guard !userId.isEmpty else { return }

        do {
            let updated = try await APIClient.shared.addFavoriteByName(
                userId: userId,
                wineName: wineName
            )
            self.userProfile = updated
            if let survey = updated.surveyAnswers {
                self.lastSurveyAnswers = survey
            }

            await loadUserProfile()
            await loadInsights()
        } catch {
            print("Failed to add favorite by name:", error)
            // later: set errorMessage
        }
    }
}


//import Foundation
//import Combine
//
//@MainActor
//final class AppState: ObservableObject {
//    @Published var userId: String = "spencer"  // hard-coded for now
//
//    @Published var lastWineProfile: WineProfile?
//    @Published var isUploadingPhoto: Bool = false
//    @Published var errorMessage: String?
//    @Published var showSuccessBanner: Bool = false
//    @Published var lastSurveyAnswers: TasteSurveyAnswers = .default
//    @Published var isSubmittingSurvey: Bool = false
//    @Published var surveySaved: Bool = false
//    @Published var userProfile: UserProfileDTO?
//    @Published var isLoadingProfile: Bool = false
//    @Published var insights: UserInsightsDTO?
//    @Published var isLoadingInsights = false
//
//    func loadInsights() async {
//        isLoadingInsights = true
//        defer { isLoadingInsights = false }
//
//        do {
//            let data = try await APIClient.shared.fetchUserInsights(userId: userId)
//            self.insights = data
//        } catch {
//            print("Failed to load insights:", error)
//        }
//    }
//
//
// 
// 
//    func addFavoriteFromPhoto(imageData: Data) async {
//        isUploadingPhoto = true
//        errorMessage = nil
//        showSuccessBanner = false
//
//        do {
//            let response = try await APIClient.shared.addFavoriteFromPhoto(
//                userId: userId,
//                imageData: imageData
//            )
//
//            self.lastWineProfile = response.wineProfile
//            self.showSuccessBanner = true
//
//            if let updatedUser = response.user {
//                print("✅ Updated user from /favorite/from-photo:",
//                      updatedUser.favoriteWines?.map(\.wineId) ?? [])
//                self.userProfile = updatedUser
//
//                if let survey = updatedUser.surveyAnswers {
//                    self.lastSurveyAnswers = survey
//                }
//            } else {
//                print("⚠️ No 'user' in response")
//            }
//            await loadUserProfile()
//        } catch {
//            if let apiError = error as? APIError {
//                errorMessage = apiError.localizedDescription
//            } else {
//                errorMessage = error.localizedDescription
//            }
//        }
//
//        isUploadingPhoto = false
//    }
//
//
//
//    func resetCurrentPhotoFlow() {
//        lastWineProfile = nil
//        errorMessage = nil
//        showSuccessBanner = false
//    }
//    func submitSurvey(answers: TasteSurveyAnswers) async {
//        isSubmittingSurvey = true
//        surveySaved = false
//        errorMessage = nil
//
//        do {
//            _ = try await APIClient.shared.submitSurvey(
//                userId: userId,
//                answers: answers
//            )
//            lastSurveyAnswers = answers
//            surveySaved = true
//        } catch {
//            if let apiError = error as? APIError {
//                errorMessage = apiError.localizedDescription
//            } else {
//                errorMessage = error.localizedDescription
//            }
//        }
//
//        isSubmittingSurvey = false
//    }
//    func loadUserProfile() async {
//        isLoadingProfile = true
//        errorMessage = nil
//
//        do {
//            let profile = try await APIClient.shared.fetchUserProfile(userId: userId)
//            userProfile = profile
//
//            // hydrate survey answers locally if present
//            if let survey = profile.surveyAnswers {
//                lastSurveyAnswers = survey
//            }
//        } catch {
//            if let apiError = error as? APIError {
//                errorMessage = apiError.localizedDescription
//            } else {
//                errorMessage = error.localizedDescription
//            }
//        }
//
//        isLoadingProfile = false
//    }
//    func addTasting(
//        wineId: String,
//        rating: Double,
//        context: String?,
//        notes: String?
//    ) async {
//        guard !userId.isEmpty else { return }
//
//        do {
//            let updatedUser = try await APIClient.shared.addTasting(
//                userId: userId,
//                wineId: wineId,
//                rating: rating,
//                context: context,
//                notes: notes
//            )
//            self.userProfile = updatedUser
//            if let survey = updatedUser.surveyAnswers {
//                self.lastSurveyAnswers = survey
//            }
//        } catch {
//            print("Failed to add tasting:", error)
//            // you can set errorMessage here later
//        }
//    }
//    
//    func addFavoriteByName(_ wineName: String) async {
//        guard !userId.isEmpty else { return }
//
//        do {
//            let updated = try await APIClient.shared.addFavoriteByName(
//                userId: userId,
//                wineName: wineName
//            )
//            self.userProfile = updated
//            if let survey = updated.surveyAnswers {
//                self.lastSurveyAnswers = survey
//            }
//        } catch {
//            print("Failed to add favorite by name:", error)
//            // later: set an error field you can show in the UI
//        }
//    }
//
//
//
//}

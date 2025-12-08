//
//  UserProfileModels.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/27/25.
//

import Foundation

struct FavoriteWineEntry: Codable, Identifiable {
    let wineId: String
    let source: String?
    let addedAt: String?

    enum CodingKeys: String, CodingKey {
        case wineId = "wine_id"
        case source
        case addedAt = "added_at"
    }

    var id: String { wineId }

    var displayName: String {
        wineId
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

struct UserProfileDTO: Codable {
    let userId: String
    let surveyAnswers: TasteSurveyAnswers?
    let styleVec: [Double]?              // ← add this back
    let favoriteWines: [FavoriteWineEntry]?
    let tastings: [TastingDTO]?

    enum CodingKeys: String, CodingKey {
        case userId        = "user_id"
        case surveyAnswers = "survey_answers"
        case styleVec      = "style_vec"
        case favoriteWines = "favorite_wines"
        case tastings
    }
}

struct UserEnvelope: Codable {
    let user: UserProfileDTO
}


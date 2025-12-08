//
//  TasteSurveyModels.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/27/25.
//
import Foundation

struct TasteSurveyAnswers: Codable, Equatable {
    var favoriteStyles: [String]
    var tanninPref: String
    var acidityPref: String
    var oakPref: String
    var adventurePref: String

    enum CodingKeys: String, CodingKey {
        case favoriteStyles = "favorite_styles"
        case tanninPref = "tannin_pref"
        case acidityPref = "acidity_pref"
        case oakPref = "oak_pref"
        case adventurePref = "adventure_pref"
    }


    static var `default`: TasteSurveyAnswers {
        TasteSurveyAnswers(
            favoriteStyles: [],
            tanninPref: "medium",
            acidityPref: "medium",
            oakPref: "low",
            adventurePref: "medium"
        )
    }
}

struct SurveyResponse: Codable {
    let status: String
}


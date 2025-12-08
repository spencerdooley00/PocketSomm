//
//  WineModels.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/26/25.
//

import Foundation

struct WineProfileResponse: Codable {
    let status: String
    let wineProfile: WineProfile
    let user: UserProfileDTO?

    enum CodingKeys: String, CodingKey {
        case status
        case wineProfile = "wine_profile"
        case user
    }
}

struct WineProfile: Codable {
    let resolvedName: String?
    let producer: String?
    let country: String?
    let region: String?
    let appellation: String?
    let color: String?
    let grapes: [String]?
    let vintageTypical: String?
    let confidence: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case resolvedName = "resolved_name"
        case producer
        case country
        case region
        case appellation
        case color
        case grapes
        case vintageTypical = "vintage_typical"
        case confidence
        case notes
    }
}

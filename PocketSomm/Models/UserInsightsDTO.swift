//
//  ProfileSummaryDTO.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/29/25.
//

import Foundation

struct UserInsightsDTO: Codable {
    let summary: String
    let topGrapes: [String]
    let topCountries: [String]
    let topRegions: [String]
    let topVintages: [Int]

    enum CodingKeys: String, CodingKey {
        case summary
        case topGrapes    = "top_grapes"
        case topCountries = "top_countries"
        case topRegions   = "top_regions"
        case topVintages  = "top_vintages"
    }
}

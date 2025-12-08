//
//  WineDetailModels.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/27/25.
//

import Foundation
struct WineDetailDTO: Codable, Identifiable {
    let wineId: String
    let name: String
    let producer: String?
    let country: String?
    let region: String?
    let appellation: String?
    let color: String?
    let grapesLine: String?
    let embeddingText: String?

    // ✅ image fields
    let imageBase64: String?
    let imageURL: String?

    var id: String { wineId }

    enum CodingKeys: String, CodingKey {
        case wineId        = "wine_id"
        case name
        case producer
        case country
        case region
        case appellation
        case color
        case grapesLine    = "grapes_line"
        case embeddingText = "embedding_text"
        case imageBase64   = "image_base64"
        case imageURL      = "image_url"
    }






    var displayName: String {
        name ?? wineId
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    var regionLine: String {
        [appellation, region, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }


}

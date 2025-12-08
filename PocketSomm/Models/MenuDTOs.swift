//
//  MenuDTOs.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/28/25.
//

import Foundation

struct MenuWineDTO: Codable, Identifiable {
    let wineId: String
    let label: String

    var id: String { wineId }

    enum CodingKeys: String, CodingKey {
        case wineId = "wine_id"
        case label
    }
}

// If you want to use `results` later, we can model it.
// For now, we only care about `menu_wines`.
struct MenuRecommendationResponseDTO: Codable {
    let status: String
    let menuWines: [MenuWineDTO]

    enum CodingKeys: String, CodingKey {
        case status
        case menuWines = "menu_wines"
    }
}

struct MenuPdfRequestBody: Codable {
    let pdf_base64: String
}

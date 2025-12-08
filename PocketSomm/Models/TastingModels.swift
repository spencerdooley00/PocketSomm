//
//  TastingModels.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/27/25.
//

import Foundation

struct AddTastingRequest: Codable {
    let wine_id: String
    let rating: Double
    let context: String?
    let notes: String?
}

struct TastingDTO: Codable, Identifiable {
    let id = UUID()   // backend doesn’t define an id, fine for now
    let wineId: String
    let rating: Double
    let context: String?
    let notes: String?
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case wineId = "wine_id"
        case rating
        case context
        case notes
        case timestamp
    }
}

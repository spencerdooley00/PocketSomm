//
//  WineSearchDTO.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/29/25.
//

import Foundation

struct WineSearchResultDTO: Codable, Identifiable {
    let wineId: String
    let name: String
    let producer: String?

    var id: String { wineId }

    enum CodingKeys: String, CodingKey {
        case wineId   = "wine_id"
        case name
        case producer
    }
}

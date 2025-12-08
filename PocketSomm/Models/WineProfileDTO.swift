//
//  WineProfileDTO.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 12/1/25.
//

import Foundation

struct WineProfileDTO: Codable {
    let inputName: String?
    let resolvedName: String?
    let producer: String?
    let country: String?
    let region: String?
    let appellation: String?
    let color: String?
    let grapes: [String]?
    let vintageTypical: String?
    let body: String?
    let acidity: String?
    let tannin: String?
    let sweetness: String?
    let oak: String?
    let styleDescription: String?
    let notFound: Bool?

    enum CodingKeys: String, CodingKey {
        case inputName        = "input_name"
        case resolvedName     = "resolved_name"
        case producer
        case country
        case region
        case appellation
        case color
        case grapes
        case vintageTypical   = "vintage_typical"
        case body
        case acidity
        case tannin
        case sweetness
        case oak
        case styleDescription = "style_description"
        case notFound         = "not_found"
    }
}

struct ResolveWineResponseDTO: Codable {
    let status: String
    let profile: WineProfileDTO
}

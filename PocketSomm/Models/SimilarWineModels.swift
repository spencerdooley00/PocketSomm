//
//  SimilarWineModels.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/27/25.
//

import Foundation

struct SimilarWinesResponse: Codable {
    let wine_id: String
    let similar: [SimilarWineDTO]
}

struct SimilarWineDTO: Codable, Identifiable {
    var id: String { wine_id }
    let wine_id: String
    let name: String
    let producer: String?
    let region: String?
    let score: Double
}

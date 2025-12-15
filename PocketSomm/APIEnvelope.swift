//
//  APIEnvelope.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 12/14/25.
//


import Foundation

struct APIEnvelope<T: Decodable>: Decodable {
    let status: String
    let data: T
}

struct APIErrorEnvelope: Decodable {
    struct Err: Decodable {
        let code: Int
        let message: String
        let details: [String: String]?
    }
    let error: Err
}

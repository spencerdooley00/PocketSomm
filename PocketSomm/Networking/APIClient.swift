//
//  APIClient.swift
//  PocketSomm
//
//  Created by Spencer Dooley on 11/26/25.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL."
        case .serverError:
            return "Server error."
        case .decodingError:
            return "Failed to decode server response."
        case .custom(let message):
            return message
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    // TODO: replace this with your real backend URL
//    private let baseURLString = "http://192.168.12.131:8000"
    private let baseURLString = "http://10.0.0.232:8000"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120          // seconds
        config.timeoutIntervalForResource = 240        // seconds
        return URLSession(configuration: config)
    }()

    private var baseURL: URL {
        guard let url = URL(string: baseURLString) else {
            fatalError("Invalid base URL")
        }
        return url
    }

    // Health check (optional but useful)
    func healthCheck() async throws -> String {
        let url = baseURL.appendingPathComponent("/health")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.serverError
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = json["status"] as? String {
            return status
        } else {
            return "ok"
        }
    }

    // MARK: - Favorite from photo

    func addFavoriteFromPhoto(userId: String, imageData: Data) async throws -> WineProfileResponse {
        let urlString = "\(baseURLString)/user/\(userId)/favorite/from-photo"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        print("⚠️ DEBUG REQUEST URL:", url.absoluteString)

        let imageBase64 = imageData.base64EncodedString()

        let body: [String: Any] = [
            "image_base64": imageBase64,
            "content_type": "image/jpeg"
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw APIError.custom(message)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WineProfileResponse.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}

extension APIClient {
    func submitSurvey(userId: String, answers: TasteSurveyAnswers) async throws -> SurveyResponse {
        let urlString = "\(baseURLString)/user/\(userId)/survey"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        let jsonData = try encoder.encode(answers)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw APIError.custom(message)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(SurveyResponse.self, from: data)
        } catch {
            // If backend just returns {"status":"ok"} we're fine
            throw APIError.decodingError
        }
    }
    

}
extension APIClient {
    func fetchUserProfile(userId: String) async throws -> UserProfileDTO {
        let urlString = "\(baseURLString)/user/\(userId)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            print("⚠️ /user response error:", message)
            throw APIError.custom(message)
        }

        // For debugging: see what the backend is actually returning
        if let raw = String(data: data, encoding: .utf8) {
            print("📥 /user/\(userId) raw response:\n\(raw)")
        }

        let decoder = JSONDecoder()

        // Try wrapped form: { "user": { ... } }
        if let envelope = try? decoder.decode(UserEnvelope.self, from: data) {
            return envelope.user
        }

        // Fallback: direct user object { "user_id": "...", "survey_answers": {...}, ... }
        return try decoder.decode(UserProfileDTO.self, from: data)
    }
}

extension APIClient {
    func fetchWineDetail(wineId: String) async throws -> WineDetailDTO {
        let urlString = "\(baseURLString)/wine/\(wineId)"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            print("⚠️ /wine response error:", message)
            throw APIError.custom(message)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(WineDetailDTO.self, from: data)
    }
}

extension APIClient {
    func fetchSimilarWines(wineId: String) async throws -> [SimilarWineDTO] {
        let urlString = "\(baseURLString)/wine/\(wineId)/similar"
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else {
            throw APIError.custom("Bad response fetching similar wines")
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(SimilarWinesResponse.self, from: data)
        return result.similar
    }
}


extension APIClient {
    func addTasting(
        userId: String,
        wineId: String,
        rating: Double,
        context: String?,
        notes: String?
    ) async throws -> UserProfileDTO {
        let urlString = "\(baseURLString)/user/\(userId)/tasting"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = AddTastingRequest(
            wine_id: wineId,
            rating: rating,
            context: context,
            notes: notes
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw APIError.custom(message)
        }

        struct AddTastingResponse: Codable {
            let status: String
            let user: UserProfileDTO
        }

        let decoded = try JSONDecoder().decode(AddTastingResponse.self, from: data)
        return decoded.user
    }
}

struct AddFavoriteByNameRequest: Codable {
    let wine_name: String
}

extension APIClient {
    func addFavoriteByName(userId: String, wineName: String) async throws -> UserProfileDTO {
        let urlString = "\(baseURLString)/user/\(userId)/favorite/by-name"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = AddFavoriteByNameRequest(wine_name: wineName)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw APIError.custom(message)
        }

        struct AddFavoriteByNameResponse: Codable {
            let status: String
            let user: UserProfileDTO
        }

        let decoded = try JSONDecoder().decode(AddFavoriteByNameResponse.self, from: data)
        return decoded.user
    }
}
// MARK: - Menu recommendations from PDF

extension APIClient {
    func recommendFromMenuPdf(userId: String, pdfBase64: String) async throws -> [MenuWineDTO] {
        let urlString = "\(baseURLString)/user/\(userId)/menu/pdf"
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = MenuPdfRequestBody(pdf_base64: pdfBase64)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw APIError.custom(message)
        }

        let decoded = try JSONDecoder().decode(MenuRecommendationResponseDTO.self, from: data)
        return decoded.menuWines
    }
}


// MARK: - User summary

extension APIClient {
    func fetchUserInsights(userId: String) async throws -> UserInsightsDTO {
        guard let url = URL(string: "\(baseURLString)/user/\(userId)/insights") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw APIError.custom(msg)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(UserInsightsDTO.self, from: data)
    }
}


// MARK: - Wine text search

extension APIClient {
    func searchWines(query: String) async throws -> [WineSearchResultDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURLString)/wine_search?q=\(encoded)"
        print("🔎 Search URL:", urlString)

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse {
            print("🔎 Status:", http.statusCode)
        }
        print("🔎 Raw JSON:", String(data: data, encoding: .utf8) ?? "<nil>")

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw APIError.custom(message)
        }

        let decoder = JSONDecoder()
        return try decoder.decode([WineSearchResultDTO].self, from: data)
    }

}



// MARK: - Resolve wine by text (no side effects)

extension APIClient {
    func resolveWineByName(name: String) async throws -> WineProfileDTO {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw APIError.custom("Wine name cannot be empty.")
        }

        guard let url = URL(string: "\(baseURLString)/wine/resolve-text") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Body: Codable {
            let wine_name: String
        }

        let body = Body(wine_name: trimmed)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw APIError.custom(msg)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ResolveWineResponseDTO.self, from: data).profile
    }

    func addFavoriteFromProfile(userId: String, profile: WineProfileDTO) async throws {
        guard let url = URL(string: "\(baseURLString)/user/\(userId)/favorite/from-profile") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Body: Codable {
            let profile: WineProfileDTO
        }

        let body = Body(profile: profile)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw APIError.custom(msg)
        }

        // we don't need to decode the user here; AppState will reload profile
        _ = data
    }
}

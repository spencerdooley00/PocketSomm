//
//  APIClient_envelope.swift
//  PocketSomm
//
//  A refactored API client that understands the backend's unified
//  response envelope `{ status: "ok", data: { … } }`. This client
//  decodes the inner `data` object transparently for each call and
//  throws descriptive `NetworkError`s on failure. It also exposes a
//  configurable base URL via the `API_BASE_URL` Info.plist key.
//

import Foundation

/// A refined set of errors that can be thrown from APIClient.
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case badResponse(Int)
    case decoding(Error)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL."
        case .badResponse(let code):
            return "Server returned HTTP \(code)."
        case .decoding:
            return "Unexpected response format from server."
        case .server(let message):
            return message
        }
    }
}

/// The shared API client used by the app to communicate with the backend.
final class APIClient {
    static let shared = APIClient()
    private init() {}

    /// Read the base URL from Info.plist or fall back to localhost.
    private var baseURLString: String {
        Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? "http://10.0.0.232:8000"
    }

    private var baseURL: URL {
        guard let url = URL(string: baseURLString) else { fatalError("Invalid API_BASE_URL: \(baseURLString)") }
        return url
    }

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 240
        return URLSession(configuration: config)
    }()

    // MARK: - Generic decoding helper

    /// Decode a response from the backend. If the payload is wrapped in
    /// `APIEnvelope<T>`, this helper will unwrap the `data` field.
    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        // First attempt to decode the new envelope format
        if let env = try? decoder.decode(APIEnvelope<T>.self, from: data) {
            return env.data
        }
        // Fall back to decoding the bare type (for backward compatibility)
        return try decoder.decode(T.self, from: data)
    }

    /// Decode an error payload if present. Returns `NetworkError.server` if a
    /// structured error exists.
    private func decodeError(from data: Data, statusCode: Int) -> NetworkError {
        let decoder = JSONDecoder()
        if let err = try? decoder.decode(APIErrorEnvelope.self, from: data) {
            return .server(err.error.message)
        }
        return .badResponse(statusCode)
    }

    // MARK: - Endpoint implementations

    /// Health check endpoint. Returns "ok" when the server is healthy.
    func healthCheck() async throws -> String {
        let url = baseURL.appendingPathComponent("/health")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.badResponse(-1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        // health endpoint always returns { status: "ok", data: { status: "ok" } }
        if let env = try? JSONDecoder().decode(APIEnvelope<[String: String]>.self, from: data) {
            return env.data["status"] ?? "ok"
        }
        // fallback: plain { status: "ok" }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = obj["status"] as? String {
            return status
        }
        return "ok"
    }

    /// Add a favorite from a photo.
    func addFavoriteFromPhoto(userId: String, imageData: Data) async throws -> (wineProfile: WineProfile, user: UserProfileDTO?) {
        let url = baseURL.appendingPathComponent("/user/\(userId)/favorite/from-photo")
        let body = [
            "image_base64": imageData.base64EncodedString(),
            "content_type": "image/jpeg"
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        struct Payload: Decodable {
            let wine_profile: WineProfile
            let user: UserProfileDTO?
        }
        let payload: Payload = try decode(Payload.self, from: data)
        return (payload.wine_profile, payload.user)
    }

    /// Submit taste survey answers.
    func submitSurvey(userId: String, answers: TasteSurveyAnswers) async throws -> UserProfileDTO {
        let url = baseURL.appendingPathComponent("/user/\(userId)/survey")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(answers)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        struct Payload: Decodable { let user: UserProfileDTO }
        let payload: Payload = try decode(Payload.self, from: data)
        return payload.user
    }

    /// Fetch a user profile.
    func fetchUserProfile(userId: String) async throws -> UserProfileDTO {
        let url = baseURL.appendingPathComponent("/user/\(userId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        struct Payload: Decodable { let user: UserProfileDTO }
        return try decode(Payload.self, from: data).user
    }

    /// Fetch wine detail.
    func fetchWineDetail(wineId: String) async throws -> WineDetailDTO {
        let url = baseURL.appendingPathComponent("/wine/\(wineId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        struct Payload: Decodable { let wine: WineDetailDTO }
        return try decode(Payload.self, from: data).wine
    }

    /// Fetch similar wines for a given wine.
    func fetchSimilarWines(wineId: String) async throws -> [SimilarWineDTO] {
        let url = baseURL.appendingPathComponent("/wine/\(wineId)/similar")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        struct Payload: Decodable { let wine_id: String; let similar: [SimilarWineDTO] }
        let payload: Payload = try decode(Payload.self, from: data)
        return payload.similar
    }

    /// Add a tasting.
    func addTasting(userId: String, wineId: String, rating: Double, context: String?, notes: String?) async throws -> UserProfileDTO {
        let url = baseURL.appendingPathComponent("/user/\(userId)/tasting")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Body: Codable {
            let wine_id: String
            let rating: Double
            let context: String?
            let notes: String?
        }
        let body = Body(wine_id: wineId, rating: rating, context: context, notes: notes)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        struct Payload: Decodable { let user: UserProfileDTO }
        return try decode(Payload.self, from: data).user
    }

    /// Add a favorite by free-text name.
    func addFavoriteByName(userId: String, wineName: String) async throws -> UserProfileDTO {
        let url = baseURL.appendingPathComponent("/user/\(userId)/favorite/by-name")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Body: Codable { let wine_name: String }
        request.httpBody = try JSONEncoder().encode(Body(wine_name: wineName))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        struct Payload: Decodable { let user: UserProfileDTO }
        return try decode(Payload.self, from: data).user
    }

    /// Recommend wines from a menu PDF.
    func recommendFromMenuPdf(userId: String, pdfBase64: String) async throws -> [MenuWineDTO] {
        let url = baseURL.appendingPathComponent("/user/\(userId)/menu/pdf")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Body: Codable { let pdf_base64: String }
        request.httpBody = try JSONEncoder().encode(Body(pdf_base64: pdfBase64))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        // The backend wraps the menu recommendations under data.menu_wines and includes results which we ignore.
        struct Payload: Decodable {
            let menu_wines: [MenuWineDTO]
            enum CodingKeys: String, CodingKey {
                case menu_wines
            }
        }
        let payload: Payload = try decode(Payload.self, from: data)
        return payload.menu_wines
    }

    /// Fetch user insights.
    func fetchUserInsights(userId: String) async throws -> UserInsightsDTO {
        let url = baseURL.appendingPathComponent("/user/\(userId)/insights")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        return try decode(UserInsightsDTO.self, from: data)
    }

    /// Search wines by query.
    func searchWines(query: String) async throws -> [WineSearchResultDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NetworkError.invalidURL
        }
        let url = baseURL.appendingPathComponent("/wine_search?q=\(encoded)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        struct Payload: Decodable { let results: [WineSearchResultDTO] }
        let payload: Payload = try decode(Payload.self, from: data)
        return payload.results
    }

    /// Resolve a wine by free-text name (search and return profile).
    func resolveWineByName(name: String) async throws -> WineProfileDTO {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw NetworkError.server("Wine name cannot be empty.") }
        let url = baseURL.appendingPathComponent("/wine/resolve-text")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Body: Codable { let wine_name: String }
        request.httpBody = try JSONEncoder().encode(Body(wine_name: trimmed))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        struct Payload: Decodable { let profile: WineProfileDTO }
        return try decode(Payload.self, from: data).profile
    }

    /// Add a favorite from a resolved profile.
    func addFavoriteFromProfile(userId: String, profile: WineProfileDTO) async throws {
        let url = baseURL.appendingPathComponent("/user/\(userId)/favorite/from-profile")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Body: Codable { let profile: WineProfileDTO }
        request.httpBody = try JSONEncoder().encode(Body(profile: profile))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badResponse(-1) }
        guard (200..<300).contains(http.statusCode) else {
            throw decodeError(from: data, statusCode: http.statusCode)
        }
        // success returns no body or an empty envelope; nothing to decode
        _ = data
    }
}

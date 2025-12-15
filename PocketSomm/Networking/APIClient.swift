//
//  APIClient_fixed.swift
//  PocketSomm
//
//  This version of APIClient reads the base URL from the app's Info.plist
//  (API_BASE_URL) instead of hard-coding it in the source. It also defines
//  the AddFavoriteByNameRequest type so that the compiler can find it.
//  Use this in place of your original APIClient.swift.
//
//  Created by Refactored on 12/15/2025.

import Foundation

enum NetworkError: Error, LocalizedError {
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
        case .custom(let msg):
            return msg
        }
    }
}

/// APIClient exposes asynchronous methods to communicate with the PocketSomm backend.
///
/// It reads the base URL from the `API_BASE_URL` key in the app's Info.plist. If that key
/// is not present the client will default to `http://10.0.0.232:8000`. To switch
/// environments (e.g. development, staging, production) you can set `API_BASE_URL` in
/// your scheme's build settings or an `.xcconfig` file.
final class APIClient {
    static let shared = APIClient()
    private init() {}

    /// Read the API base URL from the app's Info.plist (key: API_BASE_URL). Falls back to localhost.
    private var baseURLString: String {
        return Bundle.main.infoDictionary?["API_BASE_URL"] as? String ?? "http://10.0.0.232:8000"
    }

    private var baseURL: URL {
        guard let url = URL(string: baseURLString) else {
            fatalError("Invalid base URL: \(baseURLString)")
        }
        return url
    }

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 240
        return URLSession(configuration: config)
    }()

    // MARK: - Health check
    func healthCheck() async throws -> String {
        let url = baseURL.appendingPathComponent("/health")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NetworkError.serverError
        }
        // Expect the backend to return {"status":"ok"} or {"status":"ok","data":{...}}
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = json["status"] as? String {
            return status
        }
        return "ok"
    }

    // MARK: - Favorite from photo
    func addFavoriteFromPhoto(userId: String, imageData: Data) async throws -> WineProfileResponse {
        let url = baseURL.appendingPathComponent("/user/\(userId)/favorite/from-photo")
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
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(message)
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WineProfileResponse.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    // MARK: - Survey
    func submitSurvey(userId: String, answers: TasteSurveyAnswers) async throws -> SurveyResponse {
        let url = baseURL.appendingPathComponent("/user/\(userId)/survey")
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(answers)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(message)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(SurveyResponse.self, from: data)
    }

    // MARK: - User profile
    func fetchUserProfile(userId: String) async throws -> UserProfileDTO {
        let url = baseURL.appendingPathComponent("/user/\(userId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(message)
        }
        if let raw = String(data: data, encoding: .utf8) {
            print("📥 /user/\(userId) raw response:\n\(raw)")
        }
        let decoder = JSONDecoder()
        // Try wrapped form {"user": {...}}
        if let envelope = try? decoder.decode(UserEnvelope.self, from: data) {
            return envelope.user
        }
        return try decoder.decode(UserProfileDTO.self, from: data)
    }

    // MARK: - Wine detail
    func fetchWineDetail(wineId: String) async throws -> WineDetailDTO {
        let url = baseURL.appendingPathComponent("/wine/\(wineId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(message)
        }
        let decoder = JSONDecoder()
        return try decoder.decode(WineDetailDTO.self, from: data)
    }

    // MARK: - Similar wines
    func fetchSimilarWines(wineId: String) async throws -> [SimilarWineDTO] {
        let url = baseURL.appendingPathComponent("/wine/\(wineId)/similar")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NetworkError.custom("Bad response fetching similar wines")
        }
        let decoder = JSONDecoder()
        let result = try decoder.decode(SimilarWinesResponse.self, from: data)
        return result.similar
    }

    // MARK: - Add tasting
    func addTasting(
        userId: String,
        wineId: String,
        rating: Double,
        context: String?,
        notes: String?
    ) async throws -> UserProfileDTO {
        let url = baseURL.appendingPathComponent("/user/\(userId)/tasting")
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
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(message)
        }
        struct AddTastingResponse: Codable {
            let status: String
            let user: UserProfileDTO
        }
        let decoded = try JSONDecoder().decode(AddTastingResponse.self, from: data)
        return decoded.user
    }

    // MARK: - Add favorite by name
    func addFavoriteByName(userId: String, wineName: String) async throws -> UserProfileDTO {
        let url = baseURL.appendingPathComponent("/user/\(userId)/favorite/by-name")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = AddFavoriteByNameRequest(wine_name: wineName)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(message)
        }
        struct AddFavoriteByNameResponse: Codable {
            let status: String
            let user: UserProfileDTO
        }
        struct UserResponse: Decodable { let user: UserProfileDTO }

        let env = try JSONDecoder().decode(APIEnvelope<UserResponse>.self, from: data)
        return env.data.user

    }

    // MARK: - Menu recommendations
    func recommendFromMenuPdf(userId: String, pdfBase64: String) async throws -> [MenuWineDTO] {
        let url = baseURL.appendingPathComponent("/user/\(userId)/menu/pdf")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = MenuPdfRequestBody(pdf_base64: pdfBase64)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(message)
        }
        let decoded = try JSONDecoder().decode(MenuRecommendationResponseDTO.self, from: data)
        return decoded.menuWines
    }

    // MARK: - User insights
    func fetchUserInsights(userId: String) async throws -> UserInsightsDTO {
        let url = baseURL.appendingPathComponent("/user/\(userId)/insights")
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(msg)
        }
        return try JSONDecoder().decode(UserInsightsDTO.self, from: data)
    }

    // MARK: - Wine search
    func searchWines(query: String) async throws -> [WineSearchResultDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = baseURL.appendingPathComponent("/wine_search?q=\(encoded)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(message)
        }
        return try JSONDecoder().decode([WineSearchResultDTO].self, from: data)
    }

    // MARK: - Resolve wine by name
    func resolveWineByName(name: String) async throws -> WineProfileDTO {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw NetworkError.custom("Wine name cannot be empty.")
        }
        let url = baseURL.appendingPathComponent("/wine/resolve-text")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Body: Codable { let wine_name: String }
        let body = Body(wine_name: trimmed)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(msg)
        }
        return try JSONDecoder().decode(ResolveWineResponseDTO.self, from: data).profile
    }

    func addFavoriteFromProfile(userId: String, profile: WineProfileDTO) async throws {
        let url = baseURL.appendingPathComponent("/user/\(userId)/favorite/from-profile")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct Body: Codable { let profile: WineProfileDTO }
        let body = Body(profile: profile)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.custom(msg)
        }
        _ = data
    }

    // MARK: - Private helper types
    /// Request body for adding a favorite wine by name.
    ///
    /// The backend expects the JSON payload to include a single field `wine_name` with the name
    /// of the wine. Without this type the compiler will complain that `AddFavoriteByNameRequest` is undefined.
    private struct AddFavoriteByNameRequest: Codable {
        let wine_name: String
    }
}

import Foundation

/// A generic wrapper for successful responses from the PocketSomm backend.
///
/// The backend returns JSON in the form `{ "status": "ok", "data": { ... } }`.
/// Decoding into `APIEnvelope<T>` will extract the inner `data` payload as type `T`.
public struct APIEnvelope<T: Decodable>: Decodable {
    public let status: String
    public let data: T
}

/// A wrapper for error responses from the backend.
///
/// Error payloads have the form:
/// `{ "error": { "code": Int, "message": String, "details": Optional<[String: String]> } }`.
public struct APIErrorEnvelope: Decodable {
    public struct APIErrorDetail: Decodable {
        public let code: Int
        public let message: String
        public let details: [String: String]?
    }
    public let error: APIErrorDetail
}

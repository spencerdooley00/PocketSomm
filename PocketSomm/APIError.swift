import Foundation

/// Shared API error type used across the app (AppState + APIClient).
///
/// AppState casts caught errors to `APIError` to show user-friendly messages.
/// APIClient should throw this instead of raw Error values.
enum APIError: Error, LocalizedError {

    /// API_BASE_URL missing or malformed
    case invalidBaseURL(String)

    /// Request could not be built
    case invalidRequest

    /// Network transport error (no internet, timeout, DNS, etc.)
    case transport(Error)

    /// Non-2xx HTTP response
    case http(statusCode: Int, message: String? = nil)

    /// JSON decoding failed
    case decoding(Error)

    /// Fallback
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL(let raw):
            return "Invalid API configuration: \(raw)"

        case .invalidRequest:
            return "Could not create the request."

        case .transport(let err):
            return err.localizedDescription

        case .http(let statusCode, let message):
            if let message, !message.isEmpty {
                return message
            }
            return "Server error (HTTP \(statusCode))."

        case .decoding:
            return "Unexpected server response."

        case .unknown(let err):
            return err.localizedDescription
        }
    }
}

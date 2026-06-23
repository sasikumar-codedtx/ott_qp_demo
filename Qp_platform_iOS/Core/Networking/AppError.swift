import Foundation

enum AppError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkUnavailable
    case decodingFailed
    case invalidOTP
    case persistenceFailed
    case profileUnavailable
    case profileLimitReached

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .invalidResponse:
            return "The server response was invalid."
        case .networkUnavailable:
            return "The network is unavailable."
        case .decodingFailed:
            return "The server response could not be decoded."
        case .invalidOTP:
            return AppStrings.Auth.invalidOTP
        case .persistenceFailed:
            return "We could not save your changes."
        case .profileUnavailable:
            return "Keep at least one profile."
        case .profileLimitReached:
            return "You can create up to five profiles."
        }
    }
}

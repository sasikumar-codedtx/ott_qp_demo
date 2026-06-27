import Foundation

enum StorefrontPolicy: String, Codable, Equatable, Hashable {
    case entertainment
    case realityEntertainment
    case reality
    case realitySports
    case sportsEntertainment
    case sports

    nonisolated var chrtValue: String {
        switch self {
        case .entertainment:
            return "entertainment"
        case .realityEntertainment:
            return "sony2"
        case .reality:
            return "reality"
        case .realitySports:
            return "sony3"
        case .sportsEntertainment:
            return "sony1"
        case .sports:
            return "sports"
        }
    }

    nonisolated var displayName: String {
        switch self {
        case .entertainment:
            return "Entertainment"
        case .realityEntertainment:
            return "Reality + Entertainment"
        case .reality:
            return "Reality"
        case .realitySports:
            return "Reality + Sports"
        case .sportsEntertainment:
            return "Sports + Entertainment"
        case .sports:
            return "Sports"
        }
    }
}

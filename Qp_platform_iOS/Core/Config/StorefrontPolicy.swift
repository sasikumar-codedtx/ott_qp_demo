import Foundation

enum StorefrontPolicy: String, CaseIterable, Codable, Equatable, Hashable, Identifiable {
    case entertainment
    case realityEntertainment
    case reality
    case realitySports
    case sportsEntertainment
    case sports

    nonisolated var id: String { rawValue }

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

    nonisolated var subtitle: String {
        switch self {
        case .entertainment:
            return "Default entertainment storefront"
        case .realityEntertainment:
            return "Reality rail boosted into entertainment"
        case .reality:
            return "Full reality storefront"
        case .realitySports:
            return "Reality storefront with sports boost"
        case .sportsEntertainment:
            return "Sports boost inside entertainment"
        case .sports:
            return "Full sports storefront"
        }
    }
}

import Foundation

enum QuickplayCohort: String, Codable, CaseIterable, Hashable {
    case entertainment
    case sports
    case kids
    case realityShows

    nonisolated var title: String {
        switch self {
        case .entertainment:
            return "Entertainment"
        case .sports:
            return "Sports"
        case .kids:
            return "Kids"
        case .realityShows:
            return "Reality Shows"
        }
    }

    nonisolated var profileFlag: String {
        switch self {
        case .entertainment, .realityShows:
            return "regular"
        case .sports:
            return "preschool"
        case .kids:
            return "kids"
        }
    }

    nonisolated var storefrontID: String {
        switch self {
        case .entertainment:
            return "EBFB096C-CA11-4E32-A231-8A7FA15B5E13"
        case .sports:
            return "DCBF412C-437B-404F-BE31-F18D7F4BEB87"
        case .realityShows, .kids:
            return "383C7B3E-0BC0-4629-B80C-BC074EA96753"
        }
    }
}

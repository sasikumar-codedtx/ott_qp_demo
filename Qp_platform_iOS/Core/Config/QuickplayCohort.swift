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
        case .entertainment:
            return "regular"
        case .sports:
            return "kids"
        case .realityShows:
            return "Preschool"
        case .kids:
            return "kids"
        }
    }
}

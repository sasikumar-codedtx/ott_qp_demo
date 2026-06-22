import Foundation

enum QuickplayCohort: String, Codable, CaseIterable, Hashable {
    case entertainment
    case sports
    case kids
    case realityShows

    var title: String {
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

    var profileFlag: String {
        switch self {
        case .entertainment, .realityShows:
            return "regular"
        case .sports:
            return "preschool"
        case .kids:
            return "kids"
        }
    }

    var storefrontID: String {
        switch self {
        case .entertainment, .realityShows:
            return "EBFB096C-CA11-4E32-A231-8A7FA15B5E13"
        case .sports:
            return "64FBBA08-49B1-49C6-8F8D-B7F2D3CDA7F6"
        case .kids:
            return "0A328EC5-E221-4AE1-924B-1FAD40E321D2"
        }
    }
}

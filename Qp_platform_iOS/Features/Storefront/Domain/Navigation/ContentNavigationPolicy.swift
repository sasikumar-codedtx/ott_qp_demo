import Foundation

enum ContentNavigationDestination: Equatable {
    case detail
    case player
    case collection
    case unsupported(String)
}

enum ContentNavigationPolicy {
    private static let detailTypes: Set<String> = [
        "movie",
        "tvseries",
        "tvseason",
        "tvepisode",
        "webseries",
        "webseason",
        "webepisode",
        "sporthighlight"
    ]

    private static let playerTypes: Set<String> = [
        "trailer",
        "shortvideo",
        "short video",
        "short",
        "shorts",
        "promo",
        "channel",
        "liveevent",
        "live event",
        "event",
        "(vod)event",
        "vod event"
    ]

    private static let collectionTypes: Set<String> = [
        "collection",
        "view_all",
        "view all",
        "viewall"
    ]

    static func destination(for item: StorefrontItem) -> ContentNavigationDestination {
        let type = normalized(item.contentType)
        let cardType = normalized(item.cardType ?? "")

        if collectionTypes.contains(type) || collectionTypes.contains(cardType) {
            return .collection
        }

        if detailTypes.contains(type) {
            return .detail
        }

        if playerTypes.contains(type) || type.contains("short") || type.contains("clip") || type.contains("highlight") {
            return .player
        }

        return .unsupported(item.contentType)
    }

    private static func normalized(_ rawValue: String) -> String {
        rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }
}

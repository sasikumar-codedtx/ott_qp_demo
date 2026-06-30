import Foundation

struct ShortsPost: Identifiable, Equatable, Hashable {
    let id: String
    let brandLines: [String]
    let creator: String
    let caption: String
    let durationLabel: String
    let category: String
    let likeCount: Int
    let shareCount: Int
    let accentHex: String
    let videoURL: URL
    let sourceItem: StorefrontItem?

    func likeCountLabel(isLiked: Bool) -> String {
        Self.formatCount(likeCount + (isLiked ? 1 : 0))
    }

    var shareCountLabel: String {
        Self.formatCount(shareCount)
    }

    private static func formatCount(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }

        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }

        return "\(value)"
    }
}

extension ShortsPost {
    init?(item: StorefrontItem) {
        guard let videoURL = item.shortVideoURL else {
            return nil
        }

        let titleWords = item.title
            .split(separator: " ")
            .map(String.init)
        let brandLines: [String]
        if titleWords.count >= 2 {
            let midpoint = max(1, titleWords.count / 2)
            brandLines = [
                titleWords.prefix(midpoint).joined(separator: " ").uppercased(),
                titleWords.dropFirst(midpoint).joined(separator: " ").uppercased()
            ].filter { !$0.isEmpty }
        } else {
            brandLines = [item.title.uppercased()]
        }

        let stableSeed = abs(item.id.hashValue)
        self.init(
            id: item.id,
            brandLines: brandLines.isEmpty ? ["SHORTS"] : brandLines,
            creator: item.genres.first ?? item.contentType.capitalized,
            caption: item.description.nilIfEmpty ?? item.title,
            durationLabel: Self.durationLabel(seconds: item.runtimeSeconds),
            category: item.genres.first ?? item.contentType.capitalized,
            likeCount: 12_000 + stableSeed % 18_000,
            shareCount: 300 + stableSeed % 1_200,
            accentHex: Self.palette[stableSeed % Self.palette.count],
            videoURL: videoURL,
            sourceItem: item
        )
    }

    private static let palette = [
        "FF8B00",
        "E93A6B",
        "1FC8FF",
        "30D1A3",
        "2B6FFF",
        "FF5B4D"
    ]

    private static func durationLabel(seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "" }
        if seconds >= 3_600 {
            return "\(seconds / 3_600)h \(seconds % 3_600 / 60)m"
        }
        if seconds >= 60 {
            return "\(seconds / 60)m"
        }
        return "\(seconds)s"
    }
}

import Foundation

struct StorefrontItem: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let description: String
    let contentType: String
    let slug: String?
    let resourceURN: String?
    let year: String?
    let genres: [String]
    let rating: String?
    let isPremium: Bool
    let quality: String?
    let availableRatios: [String]
    let runtimeSeconds: Int?
    let progress: Double?
    let canOpenDetail: Bool

    func imageURL(for ratio: String, width: Int) -> URL? {
        let resolvedRatio = availableRatios.contains(ratio)
            ? ratio
            : (availableRatios.first(where: { $0 == "0-2x3" || $0 == "0-16x9" || $0 == "0-1x1" || $0 == "0-9x16" }) ?? ratio)

        return URL(string: "\(AppEnvironment.Endpoint.fallbackImageBaseURL)/image/\(id)/\(resolvedRatio).png?width=\(width)")
    }

    var primaryMetaText: String {
        let parts = [year, genres.prefix(2).joined(separator: ", ").nilIfEmpty].compactMap { $0 }
        return parts.joined(separator: " • ")
    }

    var watchLabel: String {
        if let progress, progress > 0.01 {
            return "Resume"
        }

        switch contentType.lowercased() {
        case "movie":
            return "Watch Movie"
        case "tvseries", "webseries", "webepisode":
            return "Watch Show"
        case "trailer":
            return "Watch Trailer"
        case let type where type.contains("sport"):
            return "Watch Live"
        default:
            return "Watch Now"
        }
    }

    var detailID: String? {
        canOpenDetail ? id : nil
    }

    var showsInlinePlayCTA: Bool {
        let type = contentType.lowercased()

        if type.contains("short") || type.contains("clip") || type.contains("highlight") {
            return true
        }

        if type.contains("trailer") || type.contains("promo") {
            return true
        }

        if type.contains("live") || type.contains("channel") {
            return true
        }

        return false
    }

    func withProgress(_ value: Double?) -> StorefrontItem {
        StorefrontItem(
            id: id,
            title: title,
            description: description,
            contentType: contentType,
            slug: slug,
            resourceURN: resourceURN,
            year: year,
            genres: genres,
            rating: rating,
            isPremium: isPremium,
            quality: quality,
            availableRatios: availableRatios,
            runtimeSeconds: runtimeSeconds,
            progress: value,
            canOpenDetail: canOpenDetail
        )
    }
}

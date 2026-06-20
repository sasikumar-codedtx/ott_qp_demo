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

    func imageURL(for ratio: String, width: Int) -> URL? {
        let resolvedRatio = availableRatios.contains(ratio)
            ? ratio
            : (availableRatios.first(where: { $0 == "0-2x3" || $0 == "0-16x9" || $0 == "0-1x1" || $0 == "0-9x16" }) ?? ratio)

        return URL(string: "\(AppEnvironment.Endpoint.imageBaseURL)/image/\(id)/\(resolvedRatio).png?width=\(width)")
    }

    var primaryMetaText: String {
        let parts = [year, genres.prefix(2).joined(separator: ", ").nilIfEmpty].compactMap { $0 }
        return parts.joined(separator: " • ")
    }

    var watchLabel: String {
        if let progress, progress > 0.01 {
            return "Resume"
        }

        switch contentType {
        case "movie":
            return "Watch Movie"
        case "webseries", "webepisode":
            return "Watch Show"
        case "trailer":
            return "Watch Trailer"
        default:
            return "Watch Now"
        }
    }

    var detailPath: String? {
        guard let slug, !slug.isEmpty else { return nil }

        let normalizedType: String
        switch contentType {
        case "movie", "webseries", "webepisode", "trailer":
            normalizedType = contentType
        default:
            normalizedType = "movie"
        }

        return "urn/resource/catalog/\(normalizedType)/\(slug)"
    }
}

import Foundation

struct StorefrontItem: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let title: String
    let description: String
    let contentType: String
    let cardType: String?
    let customSearchCategory: String?
    let customID: String?
    let collectionURL: String?
    let collectionQueryIDs: String?
    let seriesId: String?
    let slug: String?
    let resourceURN: String?
    let year: String?
    let releaseDate: String?
    let genres: [String]
    let rating: String?
    let isPremium: Bool
    let quality: String?
    let availableRatios: [String]
    let runtimeSeconds: Int?
    let progress: Double?
    let canOpenDetail: Bool
    let previewURL: URL?
    let imageBaseURL: String

    func imageURL(for ratio: String, width: Int) -> URL? {
        ImageURLBuilder(baseURL: imageBaseURL).imageURL(
            id: id,
            ratio: ratio,
            availableRatios: availableRatios,
            width: width,
            preferredFallbacks: ["0-2x3", "0-16x9", "0-1x1", "0-9x16"]
        )
    }

    func titleImageURL(width: Int) -> URL? {
        guard let titleRatio = availableRatios.first(where: { ratio in
            ratio.contains("12-") || ratio.contains("13-")
        }) else {
            return nil
        }

        return ImageURLBuilder(baseURL: imageBaseURL).imageURL(
            id: id,
            ratio: titleRatio,
            availableRatios: availableRatios,
            width: width,
            preferredFallbacks: []
        )
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

    nonisolated func withProgress(_ value: Double?) -> StorefrontItem {
        StorefrontItem(
            id: id,
            title: title,
            description: description,
            contentType: contentType,
            cardType: cardType,
            customSearchCategory: customSearchCategory,
            customID: customID,
            collectionURL: collectionURL,
            collectionQueryIDs: collectionQueryIDs,
            seriesId: seriesId,
            slug: slug,
            resourceURN: resourceURN,
            year: year,
            releaseDate: releaseDate,
            genres: genres,
            rating: rating,
            isPremium: isPremium,
            quality: quality,
            availableRatios: availableRatios,
            runtimeSeconds: runtimeSeconds,
            progress: value,
            canOpenDetail: canOpenDetail,
            previewURL: previewURL,
            imageBaseURL: imageBaseURL
        )
    }
}

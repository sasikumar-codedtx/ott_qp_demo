import Foundation

struct ContentPerson: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let imageRatios: [String]
    let imageBaseURL: String
    let imagePath: String?
    let updatedTime: String?

    func imageURL(width: Int) -> URL? {
        let ratio = imageRatios.contains("0-1x1") ? "0-1x1" : (imageRatios.first ?? "0-1x1")
        let path = imagePath?.nilIfEmpty ?? id.nilIfEmpty ?? name.personImageSlug
        let trimmedBaseURL = imageBaseURL.trimmingTrailingSlashes()
        guard var components = URLComponents(string: "\(trimmedBaseURL)/image/\(path)/\(ratio).jpg") else {
            return nil
        }

        var queryItems = [URLQueryItem(name: "width", value: String(width))]
        if let updatedTime = updatedTime?.nilIfEmpty {
            queryItems.append(URLQueryItem(name: "updatedTime", value: updatedTime))
        }
        components.queryItems = queryItems
        return components.url
    }

    var initials: String {
        let parts = name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        let initials = String(parts).uppercased()
        return initials.isEmpty ? "?" : initials
    }
}

struct ContentDetail: Equatable {
    let id: String
    let title: String
    let description: String
    let contentType: String
    let year: String?
    let genres: [String]
    let rating: String?
    let runtimeSeconds: Int?
    let quality: String?
    let isPremium: Bool
    let hasFreePreview: Bool
    let sponsorNames: [String]
    let availableRatios: [String]
    let cast: [ContentPerson]
    let directorNames: [String]
    let momentSearchEnabled: Bool
    let seriesId: String?
    let previewURL: URL?
    let imageBaseURL: String

    func imageURL(for ratio: String, width: Int) -> URL? {
        ImageURLBuilder(baseURL: imageBaseURL).imageURL(
            id: id,
            ratio: ratio,
            availableRatios: availableRatios,
            width: width,
            preferredFallbacks: ["0-16x9", "11-16x9", "0-2x3", "0-1x1"]
        )
    }

    var metaLine: String {
        let runtimeText = runtimeSeconds.map(Self.formatRuntime(seconds:))
        let parts = [year, genres.prefix(3).joined(separator: " • ").nilIfEmpty, runtimeText].compactMap { $0 }
        return parts.joined(separator: " • ").uppercased()
    }

    var supportsEpisodes: Bool {
        ["webepisode", "webseries", "tvepisode", "tvseries", "series",
         "tvseason", "webseason", "season", "seasons"].contains(contentType.lowercased())
    }

    var episodeSeriesId: String {
        seriesId?.nilIfEmpty ?? id
    }

    nonisolated static func formatRuntime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)H \(minutes)M" : "\(minutes)M"
    }
}

struct ContentSeason: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
}

struct ContentEpisodeBundle: Equatable {
    let seasons: [ContentSeason]
    let selectedSeason: ContentSeason?
    let episodes: [StorefrontItem]
}

private extension String {
    var personImageSlug: String {
        lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    func trimmingTrailingSlashes() -> String {
        var value = trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasSuffix("/") {
            value.removeLast()
        }
        return value
    }
}

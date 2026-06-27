import Foundation

struct QuickplayPlaybackContent: Identifiable, Hashable {
    let id: String
    let contentId: String
    let contentType: ContentType
    let title: String
    let resumePosition: Double
    let seriesId: String?
    let seasonId: String?
    let episodeNumber: Int?
    let rating: String?
    let genre: String?

    enum ContentType: String, Hashable {
        case movie = "movie"
        case series = "series"
        case episode = "tvepisode"
        case show = "show"
        case channel = "channel"

        var catalogType: String {
            switch self {
            case .movie:                    return "movie"
            case .episode, .series, .show:  return "tvepisode"
            case .channel:                  return "channel"
            }
        }
    }

    init(
        contentId: String,
        contentType: ContentType,
        title: String,
        resumePosition: Double = 0,
        seriesId: String? = nil,
        seasonId: String? = nil,
        episodeNumber: Int? = nil,
        rating: String? = nil,
        genre: String? = nil
    ) {
        self.id = contentId
        self.contentId = contentId
        self.contentType = contentType
        self.title = title
        self.resumePosition = resumePosition
        self.seriesId = seriesId
        self.seasonId = seasonId
        self.episodeNumber = episodeNumber
        self.rating = rating
        self.genre = genre
    }
}

extension QuickplayPlaybackContent {
    static func contentType(from rawValue: String) -> ContentType {
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")

        if normalized.contains("episode") {
            return .episode
        }

        if normalized.contains("series") || normalized.contains("season") {
            return .series
        }

        if normalized.contains("show") {
            return .show
        }

        if normalized.contains("channel") || normalized.contains("live") || normalized.contains("event") {
            return .channel
        }

        return .movie
    }
}

extension StorefrontItem {
    func quickplayPlaybackContent() -> QuickplayPlaybackContent {
        QuickplayPlaybackContent(
            contentId: id,
            contentType: QuickplayPlaybackContent.contentType(from: contentType),
            title: title,
            resumePosition: (progress ?? 0) * Double(runtimeSeconds ?? 0)
        )
    }
}

extension ContentDetail {
    func quickplayPlaybackContent(fallback item: StorefrontItem?) -> QuickplayPlaybackContent {
        let resumeSeconds: Double
        if let item, let progress = item.progress {
            resumeSeconds = progress * Double(runtimeSeconds ?? item.runtimeSeconds ?? 0)
        } else {
            resumeSeconds = 0
        }

        return QuickplayPlaybackContent(
            contentId: id,
            contentType: QuickplayPlaybackContent.contentType(from: contentType),
            title: title,
            resumePosition: resumeSeconds
        )
    }
}

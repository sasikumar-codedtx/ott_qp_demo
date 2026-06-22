import Foundation

struct MockShortsRepository: ShortsRepository {
    private let posts: [ShortsPost] = {
        let baseURLs: [URL] = [
            URL(string: "https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4")!,
            URL(string: "https://www.w3schools.com/html/mov_bbb.mp4")!,
            URL(string: "https://www.w3schools.com/html/movie.mp4")!,
            URL(string: "https://media.w3.org/2010/05/sintel/trailer.mp4")!,
            URL(string: "https://media.w3.org/2010/05/bunny/trailer.mp4")!,
            URL(string: "https://media.w3.org/2010/05/video/movie_300.mp4")!
        ]

        let brandLines = [
            ["EDGE OF", "TOMORROW"],
            ["CITY", "LOOP"],
            ["MOTION", "CUT"],
            ["STREET", "BEAT"],
            ["WILD", "FRAME"],
            ["NIGHT", "DRIVE"]
        ]

        let creators = [
            "@insta.loop",
            "@travelcuts",
            "@soundframe",
            "@citysnap",
            "@reelglow",
            "@quickvibe"
        ]

        let captions = [
            "Golden-hour footage cut for a fast swipe-through mock shorts experience.",
            "Quick city clip with edge-to-edge playback and instant mute toggle on tap.",
            "A short cinematic sample to test scroll, buffer, and loop behavior cleanly.",
            "Double tap anywhere on the video to drop a heart without leaving the reel.",
            "Lightweight mock source picked so nearby buffering starts faster in the feed.",
            "Vertical demo content styled like a production shorts app with overlay actions."
        ]

        let categories = [
            "Travel",
            "Lifestyle",
            "Street",
            "Demo",
            "Nature",
            "Mood"
        ]

        let palette = [
            "FF8B00",
            "E93A6B",
            "1FC8FF",
            "30D1A3",
            "2B6FFF",
            "FF5B4D"
        ]

        return (0..<30).map { index in
            ShortsPost(
                id: "short-\(index)",
                brandLines: brandLines[index % brandLines.count],
                creator: creators[index % creators.count],
                caption: captions[index % captions.count],
                durationLabel: "\(8 + (index % 4) * 4)s",
                category: categories[index % categories.count],
                likeCount: 12_500 + (index * 137),
                shareCount: 320 + (index * 9),
                accentHex: palette[index % palette.count],
                videoURL: baseURLs[index % baseURLs.count]
            )
        }
    }()

    func fetchBatch(offset: Int, limit: Int) async throws -> ShortsBatch {
        guard offset < posts.count else {
            return ShortsBatch(posts: [], totalCount: posts.count, allVideoURLs: allVideoURLs)
        }

        let endIndex = min(offset + limit, posts.count)
        return ShortsBatch(
            posts: Array(posts[offset..<endIndex]),
            totalCount: posts.count,
            allVideoURLs: allVideoURLs
        )
    }

    private var allVideoURLs: [URL] {
        Array(Set(posts.map(\.videoURL)))
    }
}

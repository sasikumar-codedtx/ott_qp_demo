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

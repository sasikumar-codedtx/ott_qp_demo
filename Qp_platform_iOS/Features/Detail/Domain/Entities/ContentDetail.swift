import Foundation

struct ContentPerson: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let imageRatios: [String]

    func imageURL(width: Int) -> URL? {
        guard imageRatios.contains("0-1x1") else { return nil }
        return URL(string: "\(AppEnvironment.Endpoint.imageBaseURL)/image/\(id)/0-1x1.png?width=\(width)")
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

    func imageURL(for ratio: String, width: Int) -> URL? {
        let resolvedRatio = availableRatios.contains(ratio)
            ? ratio
            : (availableRatios.first(where: { $0 == "0-16x9" || $0 == "11-16x9" || $0 == "0-2x3" || $0 == "0-1x1" }) ?? ratio)

        return URL(string: "\(AppEnvironment.Endpoint.imageBaseURL)/image/\(id)/\(resolvedRatio).png?width=\(width)")
    }

    var metaLine: String {
        let runtimeText = runtimeSeconds.map(Self.formatRuntime(seconds:))
        let parts = [year, genres.prefix(3).joined(separator: " • ").nilIfEmpty, runtimeText].compactMap { $0 }
        return parts.joined(separator: " • ").uppercased()
    }

    static func formatRuntime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)H \(minutes)M" : "\(minutes)M"
    }
}

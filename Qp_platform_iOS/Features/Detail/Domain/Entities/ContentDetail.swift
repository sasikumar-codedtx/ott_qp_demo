import Foundation

struct ContentPerson: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let imageRatios: [String]
    let imageBaseURL: String

    func imageURL(width: Int) -> URL? {
        guard imageRatios.isEmpty == false else { return nil }
        return ImageURLBuilder(baseURL: imageBaseURL).imageURL(
            id: id,
            ratio: "0-1x1",
            availableRatios: imageRatios,
            width: width,
            preferredFallbacks: ["0-1x1", "0-2x3", "0-3x4", "0-16x9"]
        )
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

    nonisolated static func formatRuntime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)H \(minutes)M" : "\(minutes)M"
    }
}

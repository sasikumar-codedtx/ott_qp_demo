import Foundation

enum ProfileArtworkResolver {
    static let allAvatarImageNames = [
        "Frame 1261156185",
        "Frame 1261156184",
        "Frame 1261156186",
        "Frame 1261156187",
        "Frame 1261156183",
        "Frame 1261156188",
        "Frame 1261156189",
        "Frame 1261156192",
        "Frame 1261156191",
        "Frame 1261156190",
        "Frame 1261156193",
        "Frame 1261156194",
        "Frame 1261156207",
        "Frame 1261156214",
        "Frame 1261156209",
        "Frame 1261156210",
        "Frame 1261156211",
        "Frame 1261156212",
        "Frame 1261156195",
        "Frame 1261156196",
        "Frame 1261156197",
        "Frame 1261156198",
        "Frame 1261156199",
        "Frame 1261156200",
        "Frame 1261156201",
        "Frame 1261156202",
        "Frame 1261156203"
    ]

    static let defaultKidsImageName = "Frame 1261156187"
    static let defaultPrimaryImageName = "Frame 1261156193"

    static func imageName(for profile: Profile?) -> String? {
        guard let profile else { return allAvatarImageNames.first }
        if let imageName = profile.imageName, !imageName.isEmpty {
            return imageName
        }
        return imageName(forName: profile.name)
    }

    static func randomizedImageName(forName name: String) -> String? {
        guard !allAvatarImageNames.isEmpty else { return nil }
        let index = abs(name.hashValue) % allAvatarImageNames.count
        return allAvatarImageNames[index]
    }

    static func imageName(forName name: String) -> String? {
        switch name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "kids":
            return defaultKidsImageName
        case "prabhu":
            return defaultPrimaryImageName
        default:
            return randomizedImageName(forName: name)
        }
    }
}

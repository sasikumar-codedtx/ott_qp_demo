import Foundation

enum ProfileArtworkResolver {
    private static let fallbackAvatars = [
        "profile-randy",
        "profile-karan-main",
        "profile-hike-main",
        "profile-jhon",
        "profile-chris",
        "profile-akash"
    ]

    static func imageName(for profile: Profile?) -> String? {
        guard let profile else { return fallbackAvatars.first }
        if let imageName = profile.imageName, !imageName.isEmpty {
            return imageName
        }
        return imageName(forName: profile.name)
    }

    static func randomizedImageName(forName name: String) -> String? {
        guard !fallbackAvatars.isEmpty else { return nil }
        let index = abs(name.hashValue) % fallbackAvatars.count
        return fallbackAvatars[index]
    }

    static func imageName(forName name: String) -> String? {
        switch name {
        case "Randy Orton": return "profile-randy"
        case "Karan": return "profile-karan-main"
        case "Hike": return "profile-hike-main"
        case "Chris": return "profile-chris"
        case "Akash": return "profile-akash"
        default:
            return randomizedImageName(forName: name)
        }
    }
}

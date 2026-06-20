import Foundation

enum ProfileGender: String, CaseIterable, Identifiable, Codable {
    case male = "Male"
    case female = "Female"
    case preferNotToSay = "Prefer not to say"

    var id: String { rawValue }
}

enum PreferredContent: String, CaseIterable, Identifiable, Hashable, Codable {
    case hindi
    case english
    case telugu
    case gujarati
    case bengali
    case tamil

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

struct Profile: Identifiable, Equatable, Codable, Hashable {
    let id: UUID
    var name: String
    var imageName: String?
    var birthDate: Date?
    var gender: ProfileGender?
    var preferredContent: Set<PreferredContent>
    var isKidsProfile: Bool
    var showOnSelection: Bool

    var fallbackGlyph: String {
        String(name.prefix(1)).uppercased()
    }
}

struct AvatarOption: Identifiable, Equatable {
    let id: String
    let label: String
    let imageName: String?
}

struct ProfileDraft: Equatable {
    var sourceID: UUID?
    var name: String
    var imageName: String?
    var birthDate: Date?
    var gender: ProfileGender?
    var preferredContent: Set<PreferredContent>
    var isKidsProfile: Bool

    init(profile: Profile) {
        sourceID = profile.id
        name = profile.name
        imageName = profile.imageName
        birthDate = profile.birthDate
        gender = profile.gender
        preferredContent = profile.preferredContent
        isKidsProfile = profile.isKidsProfile
    }

    init() {
        sourceID = nil
        name = ""
        imageName = nil
        birthDate = nil
        gender = nil
        preferredContent = [.english]
        isKidsProfile = false
    }
}

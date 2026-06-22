import Foundation

enum ProfilePreference: String, CaseIterable, Identifiable, Hashable, Codable {
    case entertainment
    case sports
    case realityShows
    case microdramas

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .entertainment:
            return "Entertainment"
        case .sports:
            return "Sports"
        case .realityShows:
            return "Reality Shows"
        case .microdramas:
            return "Microdramas"
        }
    }

    var subtitle: String {
        switch self {
        case .entertainment:
            return "Movies, web series and originals"
        case .sports:
            return "Live matches, highlights and analysis"
        case .realityShows:
            return "Talent hunts, game shows and unscripted"
        case .microdramas:
            return "Snackable stories and quick episodes"
        }
    }

    var symbolName: String {
        switch self {
        case .entertainment:
            return "sparkles.tv"
        case .sports:
            return "sportscourt"
        case .realityShows:
            return "music.mic"
        case .microdramas:
            return "bolt.heart"
        }
    }

    var quickplayCohort: QuickplayCohort {
        switch self {
        case .entertainment:
            return .entertainment
        case .sports:
            return .sports
        case .realityShows:
            return .realityShows
        case .microdramas:
            return .entertainment
        }
    }
}

extension QuickplayCohort {
    var defaultPreference: ProfilePreference {
        switch self {
        case .sports:
            return .sports
        case .realityShows:
            return .realityShows
        case .kids, .entertainment:
            return .entertainment
        }
    }
}

enum ProfileGender: String, CaseIterable, Identifiable, Hashable, Codable {
    case male
    case female
    case preferNotToSay

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .preferNotToSay:
            return "Prefer not to say"
        }
    }
}

enum ProfileLanguage: String, CaseIterable, Identifiable, Hashable, Codable {
    case hindi
    case english
    case telugu
    case bengali
    case tamil
    case gujarati

    var id: String { rawValue }

    var nativeTitle: String {
        switch self {
        case .hindi:
            return "हिंदी"
        case .english:
            return "AaPtsCc"
        case .telugu:
            return "తెలుగు"
        case .bengali:
            return "বাংলা"
        case .tamil:
            return "தமிழ்"
        case .gujarati:
            return "ગુજરાતી"
        }
    }

    var englishTitle: String {
        switch self {
        case .hindi:
            return "Hindi"
        case .english:
            return "English"
        case .telugu:
            return "Telugu"
        case .bengali:
            return "Bengali"
        case .tamil:
            return "Tamil"
        case .gujarati:
            return "Gujarati"
        }
    }

    var monogram: String {
        switch self {
        case .hindi:
            return "ह"
        case .english:
            return "A"
        case .telugu:
            return "తె"
        case .bengali:
            return "বা"
        case .tamil:
            return "த"
        case .gujarati:
            return "ગુ"
        }
    }
}

struct Profile: Identifiable, Equatable, Codable, Hashable {
    let id: UUID
    var name: String
    var imageName: String?
    var preference: ProfilePreference
    var preferredLanguages: [ProfileLanguage]
    var dateOfBirth: Date?
    var gender: ProfileGender?
    var isKidsProfile: Bool
    var showOnSelection: Bool

    var fallbackGlyph: String {
        String(name.prefix(1)).uppercased()
    }

    var quickplayCohort: QuickplayCohort {
        isKidsProfile ? .kids : preference.quickplayCohort
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
    var preference: ProfilePreference
    var preferredLanguages: [ProfileLanguage]
    var dateOfBirth: Date
    var gender: ProfileGender?
    var isKidsProfile: Bool

    init(profile: Profile) {
        sourceID = profile.id
        name = profile.name
        imageName = profile.imageName
        preference = profile.preference
        preferredLanguages = profile.preferredLanguages
        dateOfBirth = profile.dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -21, to: Date()) ?? Date()
        gender = profile.gender
        isKidsProfile = profile.isKidsProfile
    }

    init() {
        sourceID = nil
        name = ""
        imageName = nil
        preference = .entertainment
        preferredLanguages = [.hindi, .english]
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -21, to: Date()) ?? Date()
        gender = nil
        isKidsProfile = false
    }
}

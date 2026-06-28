import Foundation

struct ProfileDTO: Codable {
    let id: UUID
    let name: String
    let imageName: String?
    let storefrontPolicy: StorefrontPolicy
    let preference: ProfilePreference
    let preferredLanguages: [ProfileLanguage]?
    let dateOfBirth: Date?
    let gender: ProfileGender?
    let isKidsProfile: Bool
    let showOnSelection: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageName
        case cohort
        case storefrontPolicy
        case preference
        case preferredLanguages
        case dateOfBirth
        case gender
        case isKidsProfile
        case showOnSelection
    }

    init(
        id: UUID,
        name: String,
        imageName: String?,
        storefrontPolicy: StorefrontPolicy,
        preference: ProfilePreference,
        preferredLanguages: [ProfileLanguage]?,
        dateOfBirth: Date?,
        gender: ProfileGender?,
        isKidsProfile: Bool,
        showOnSelection: Bool
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.storefrontPolicy = storefrontPolicy
        self.preference = preference
        self.preferredLanguages = preferredLanguages
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.isKidsProfile = isKidsProfile
        self.showOnSelection = showOnSelection
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
        preference = try container.decodeIfPresent(ProfilePreference.self, forKey: .preference) ?? .entertainment
        preferredLanguages = try container.decodeIfPresent([ProfileLanguage].self, forKey: .preferredLanguages)
        dateOfBirth = try container.decodeIfPresent(Date.self, forKey: .dateOfBirth)
        gender = try container.decodeIfPresent(ProfileGender.self, forKey: .gender)
        isKidsProfile = try container.decodeIfPresent(Bool.self, forKey: .isKidsProfile) ?? false
        showOnSelection = try container.decodeIfPresent(Bool.self, forKey: .showOnSelection) ?? true
        let legacyCohort = try container.decodeIfPresent(QuickplayCohort.self, forKey: .cohort) ??
            (isKidsProfile ? .kids : preference.quickplayCohort)
        storefrontPolicy = try container.decodeIfPresent(StorefrontPolicy.self, forKey: .storefrontPolicy) ??
            .defaultPolicy(for: legacyCohort)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageName, forKey: .imageName)
        try container.encode(storefrontPolicy, forKey: .storefrontPolicy)
        try container.encode(preference, forKey: .preference)
        try container.encodeIfPresent(preferredLanguages, forKey: .preferredLanguages)
        try container.encodeIfPresent(dateOfBirth, forKey: .dateOfBirth)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encode(isKidsProfile, forKey: .isKidsProfile)
        try container.encode(showOnSelection, forKey: .showOnSelection)
    }

    func toDomain() -> Profile {
        Profile(
            id: id,
            name: name,
            imageName: imageName,
            storefrontPolicy: storefrontPolicy,
            preference: preference,
            preferredLanguages: preferredLanguages ?? [],
            dateOfBirth: dateOfBirth,
            gender: gender,
            isKidsProfile: isKidsProfile,
            showOnSelection: showOnSelection
        )
    }

    static func fromDomain(_ profile: Profile) -> ProfileDTO {
        ProfileDTO(
            id: profile.id,
            name: profile.name,
            imageName: profile.imageName,
            storefrontPolicy: profile.storefrontPolicy,
            preference: profile.preference,
            preferredLanguages: profile.preferredLanguages,
            dateOfBirth: profile.dateOfBirth,
            gender: profile.gender,
            isKidsProfile: profile.isKidsProfile,
            showOnSelection: profile.showOnSelection
        )
    }
}

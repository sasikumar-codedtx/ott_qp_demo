import Foundation

struct ProfileDTO: Codable {
    let id: UUID
    let name: String
    let imageName: String?
    let preference: ProfilePreference
    let preferredLanguages: [ProfileLanguage]?
    let dateOfBirth: Date?
    let gender: ProfileGender?
    let isKidsProfile: Bool
    let showOnSelection: Bool

    func toDomain() -> Profile {
        Profile(
            id: id,
            name: name,
            imageName: imageName,
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
            preference: profile.preference,
            preferredLanguages: profile.preferredLanguages,
            dateOfBirth: profile.dateOfBirth,
            gender: profile.gender,
            isKidsProfile: profile.isKidsProfile,
            showOnSelection: profile.showOnSelection
        )
    }
}

import Foundation

struct ProfileDTO: Codable {
    let id: UUID
    let name: String
    let imageName: String?
    let birthDate: Date?
    let gender: ProfileGender?
    let preferredContent: Set<PreferredContent>
    let isKidsProfile: Bool
    let showOnSelection: Bool

    func toDomain() -> Profile {
        Profile(
            id: id,
            name: name,
            imageName: imageName,
            birthDate: birthDate,
            gender: gender,
            preferredContent: preferredContent,
            isKidsProfile: isKidsProfile,
            showOnSelection: showOnSelection
        )
    }

    static func fromDomain(_ profile: Profile) -> ProfileDTO {
        ProfileDTO(
            id: profile.id,
            name: profile.name,
            imageName: profile.imageName,
            birthDate: profile.birthDate,
            gender: profile.gender,
            preferredContent: profile.preferredContent,
            isKidsProfile: profile.isKidsProfile,
            showOnSelection: profile.showOnSelection
        )
    }
}

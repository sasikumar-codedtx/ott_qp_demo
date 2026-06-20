import Foundation

protocol ProfileDataSourceProtocol {
    func fetchProfiles() async throws -> [ProfileDTO]
    func fetchAvatarOptions() async throws -> [AvatarOption]
    func saveProfile(draft: ProfileDraft) async throws -> ProfileDTO
}

@MainActor
final class ProfileMockDataSource: ProfileDataSourceProtocol {
    private var profiles: [ProfileDTO] = [
        ProfileDTO(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
            name: "Hike",
            imageName: "profile-hike-main",
            birthDate: nil,
            gender: .male,
            preferredContent: [.hindi, .english],
            isKidsProfile: false,
            showOnSelection: true
        ),
        ProfileDTO(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
            name: "Akash",
            imageName: "profile-akash",
            birthDate: nil,
            gender: .male,
            preferredContent: [.english, .tamil],
            isKidsProfile: false,
            showOnSelection: false
        ),
        ProfileDTO(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
            name: "Randy Orton",
            imageName: "profile-randy",
            birthDate: nil,
            gender: .male,
            preferredContent: [.english, .tamil],
            isKidsProfile: false,
            showOnSelection: true
        ),
        ProfileDTO(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID(),
            name: "Chris",
            imageName: "profile-chris",
            birthDate: nil,
            gender: .male,
            preferredContent: [.english, .bengali],
            isKidsProfile: false,
            showOnSelection: false
        ),
        ProfileDTO(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555") ?? UUID(),
            name: "Karan",
            imageName: "profile-karan-main",
            birthDate: nil,
            gender: .male,
            preferredContent: [.english, .gujarati],
            isKidsProfile: false,
            showOnSelection: true
        )
    ]

    private let avatarOptions: [AvatarOption] = [
        AvatarOption(id: "profile-randy", label: "Randy", imageName: "profile-randy"),
        AvatarOption(id: "profile-karan-main", label: "Karan", imageName: "profile-karan-main"),
        AvatarOption(id: "profile-hike-main", label: "Hike", imageName: "profile-hike-main"),
        AvatarOption(id: "profile-jhon", label: "Jhon", imageName: "profile-jhon"),
        AvatarOption(id: "profile-chris", label: "Chris", imageName: "profile-chris"),
        AvatarOption(id: "profile-akash", label: "Akash", imageName: "profile-akash"),
        AvatarOption(id: "profile-karan-edit", label: "Karan 2", imageName: "profile-karan-edit"),
        AvatarOption(id: "profile-hike-edit", label: "Hike 2", imageName: "profile-hike-edit")
    ]

    func fetchProfiles() async throws -> [ProfileDTO] {
        profiles
    }

    func fetchAvatarOptions() async throws -> [AvatarOption] {
        avatarOptions
    }

    func saveProfile(draft: ProfileDraft) async throws -> ProfileDTO {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.nilIfEmpty ?? "New Profile"

        if let sourceID = draft.sourceID, let index = profiles.firstIndex(where: { $0.id == sourceID }) {
            profiles[index] = ProfileDTO(
                id: sourceID,
                name: finalName,
                imageName: draft.imageName,
                birthDate: draft.birthDate,
                gender: draft.gender,
                preferredContent: draft.preferredContent,
                isKidsProfile: draft.isKidsProfile,
                showOnSelection: true
            )
            return profiles[index]
        }

        let newProfile = ProfileDTO(
            id: UUID(),
            name: finalName,
            imageName: draft.imageName,
            birthDate: draft.birthDate,
            gender: draft.gender,
            preferredContent: draft.preferredContent,
            isKidsProfile: draft.isKidsProfile,
            showOnSelection: true
        )
        profiles.append(newProfile)
        return newProfile
    }
}

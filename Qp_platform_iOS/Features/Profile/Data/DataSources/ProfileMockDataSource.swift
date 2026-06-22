import Foundation

protocol ProfileDataSourceProtocol {
    func fetchProfiles() async throws -> [ProfileDTO]
    func fetchAvatarOptions() async throws -> [AvatarOption]
    func saveProfile(draft: ProfileDraft) async throws -> ProfileDTO
}

@MainActor
final class ProfileMockDataSource: ProfileDataSourceProtocol {
    private enum StorageKey {
        static let profiles = "sony.quickplay.demo.profiles.v4"
    }

    private var profiles: [ProfileDTO]

    private let avatarOptions: [AvatarOption] = ProfileArtworkResolver.allAvatarImageNames.enumerated().map { index, imageName in
        AvatarOption(
            id: "profile-avatar-\(index)",
            label: "Avatar \(index + 1)",
            imageName: imageName
        )
    }

    init() {
        profiles = Self.loadPersistedProfiles() ?? Self.seedProfiles
        persistProfiles()
    }

    func fetchProfiles() async throws -> [ProfileDTO] {
        profiles
    }

    func fetchAvatarOptions() async throws -> [AvatarOption] {
        avatarOptions
    }

    func saveProfile(draft: ProfileDraft) async throws -> ProfileDTO {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.nilIfEmpty ?? (draft.isKidsProfile ? "Kids" : "New Profile")

        if let sourceID = draft.sourceID, let index = profiles.firstIndex(where: { $0.id == sourceID }) {
            profiles[index] = ProfileDTO(
                id: sourceID,
                name: finalName,
                imageName: draft.imageName,
                preference: draft.preference,
                preferredLanguages: draft.preferredLanguages,
                dateOfBirth: draft.dateOfBirth,
                gender: draft.gender,
                isKidsProfile: draft.isKidsProfile,
                showOnSelection: true
            )
            persistProfiles()
            return profiles[index]
        }

        let newProfile = ProfileDTO(
            id: UUID(),
            name: finalName,
            imageName: draft.imageName,
            preference: draft.preference,
            preferredLanguages: draft.preferredLanguages,
            dateOfBirth: draft.dateOfBirth,
            gender: draft.gender,
            isKidsProfile: draft.isKidsProfile,
            showOnSelection: true
        )
        profiles.append(newProfile)
        persistProfiles()
        return newProfile
    }

    private func persistProfiles() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.profiles)
    }

    private static func loadPersistedProfiles() -> [ProfileDTO]? {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.profiles) else { return nil }
        return try? JSONDecoder().decode([ProfileDTO].self, from: data)
    }

    private static let seedProfiles: [ProfileDTO] = [
        ProfileDTO(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
            name: "Kids",
            imageName: ProfileArtworkResolver.defaultKidsImageName,
            preference: QuickplayCohort.kids.defaultPreference,
            preferredLanguages: [.hindi, .english],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 2018, month: 6, day: 10)),
            gender: .preferNotToSay,
            isKidsProfile: true,
            showOnSelection: true
        ),
        ProfileDTO(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
            name: "Prabhu",
            imageName: ProfileArtworkResolver.defaultPrimaryImageName,
            preference: .entertainment,
            preferredLanguages: [.english, .hindi],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1994, month: 7, day: 21)),
            gender: .male,
            isKidsProfile: false,
            showOnSelection: true
        )
    ]
}

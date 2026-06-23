import Foundation

protocol ProfileDataSourceProtocol {
    func fetchProfiles() async throws -> [ProfileDTO]
    func fetchAvatarOptions() async throws -> [AvatarOption]
    func saveProfile(draft: ProfileDraft) async throws -> ProfileDTO
    func deleteProfile(id: UUID) async throws
}

@MainActor
final class ProfileMockDataSource: ProfileDataSourceProtocol {
    private enum StorageKey {
        static let profiles = "sony.quickplay.demo.profiles.v5"
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

        guard profiles.filter(\.showOnSelection).count < 5 else {
            throw AppError.profileLimitReached
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

    func deleteProfile(id: UUID) async throws {
        guard profiles.count > 1 else {
            throw AppError.profileUnavailable
        }

        profiles.removeAll { $0.id == id }
        persistProfiles()
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
            name: "Jhon",
            imageName: "Frame 1261156188",
            preference: .entertainment,
            preferredLanguages: [.hindi, .english],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 2018, month: 6, day: 10)),
            gender: .preferNotToSay,
            isKidsProfile: false,
            showOnSelection: true
        ),
        ProfileDTO(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
            name: "Chris",
            imageName: "Frame 1261156195",
            preference: .entertainment,
            preferredLanguages: [.english, .hindi],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1994, month: 7, day: 21)),
            gender: .male,
            isKidsProfile: false,
            showOnSelection: true
        ),
        ProfileDTO(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
            name: "Karan",
            imageName: "Frame 1261156187",
            preference: .sports,
            preferredLanguages: [.hindi, .english],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1998, month: 2, day: 12)),
            gender: .male,
            isKidsProfile: false,
            showOnSelection: true
        ),
        ProfileDTO(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID(),
            name: "Hike",
            imageName: "Frame 1261156185",
            preference: .realityShows,
            preferredLanguages: [.english, .hindi],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1996, month: 11, day: 4)),
            gender: .preferNotToSay,
            isKidsProfile: false,
            showOnSelection: true
        ),
        ProfileDTO(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555") ?? UUID(),
            name: "Akash",
            imageName: "Frame 1261156191",
            preference: .entertainment,
            preferredLanguages: [.hindi, .english],
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1993, month: 8, day: 19)),
            gender: .male,
            isKidsProfile: false,
            showOnSelection: true
        )
    ]
}

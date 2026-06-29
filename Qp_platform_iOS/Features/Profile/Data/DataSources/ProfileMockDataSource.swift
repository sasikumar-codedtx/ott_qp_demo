import Foundation

protocol ProfileDataSourceProtocol {
    func fetchProfiles() async throws -> [ProfileDTO]
    func fetchAvatarOptions() async throws -> [AvatarOption]
    func saveProfile(draft: ProfileDraft) async throws -> ProfileDTO
    func updateProfileCohort(id: UUID, cohort: QuickplayCohort) async throws -> ProfileDTO
    func deleteProfile(id: UUID) async throws
}

@MainActor
final class ProfileMockDataSource: ProfileDataSourceProtocol {
    private static let phoneNumberKey = "sony.quickplay.demo.active-phone-number"

    private var storageKey: String {
        let phone = UserDefaults.standard.string(forKey: Self.phoneNumberKey) ?? "default"
        return "sony.quickplay.demo.profiles.v8.\(phone)"
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
        let phone = UserDefaults.standard.string(forKey: Self.phoneNumberKey) ?? "default"
        let key = "sony.quickplay.demo.profiles.v8.\(phone)"
        profiles = Self.loadPersistedProfiles(key: key) ?? []
    }

    func reloadForCurrentPhone() {
        profiles = Self.loadPersistedProfiles(key: storageKey) ?? []
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
                storefrontPolicy: draft.storefrontPolicy,
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
            storefrontPolicy: draft.storefrontPolicy,
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

    func updateProfileCohort(id: UUID, cohort: QuickplayCohort) async throws -> ProfileDTO {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else {
            throw AppError.profileUnavailable
        }

        let existing = profiles[index]
        profiles[index] = ProfileDTO(
            id: existing.id,
            name: existing.name,
            imageName: existing.imageName,
            storefrontPolicy: .defaultPolicy(for: cohort),
            preference: cohort.defaultPreference,
            preferredLanguages: existing.preferredLanguages,
            dateOfBirth: existing.dateOfBirth,
            gender: existing.gender,
            isKidsProfile: cohort == .kids,
            showOnSelection: existing.showOnSelection
        )
        persistProfiles()
        return profiles[index]
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
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static func loadPersistedProfiles(key: String) -> [ProfileDTO]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([ProfileDTO].self, from: data)
    }
}

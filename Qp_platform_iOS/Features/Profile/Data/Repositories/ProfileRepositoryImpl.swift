import Foundation

final class ProfileRepositoryImpl: ProfileRepository {
    private let dataSource: ProfileDataSourceProtocol

    init(dataSource: ProfileDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func fetchProfiles() async throws -> [Profile] {
        try await dataSource.fetchProfiles().map { $0.toDomain() }
    }

    func fetchAvatarOptions() async throws -> [AvatarOption] {
        try await dataSource.fetchAvatarOptions()
    }

    func saveProfile(draft: ProfileDraft) async throws -> Profile {
        try await dataSource.saveProfile(draft: draft).toDomain()
    }

    func updateProfileCohort(id: UUID, cohort: QuickplayCohort) async throws -> Profile {
        try await dataSource.updateProfileCohort(id: id, cohort: cohort).toDomain()
    }

    func deleteProfile(id: UUID) async throws {
        try await dataSource.deleteProfile(id: id)
    }
}

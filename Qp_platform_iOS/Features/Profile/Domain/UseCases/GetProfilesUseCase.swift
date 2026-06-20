import Foundation

struct GetProfilesUseCase {
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Profile] {
        try await repository.fetchProfiles()
    }
}

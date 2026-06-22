import Foundation

struct GetProfileHomeUseCase {
    private let repository: ProfileHubRepository

    init(repository: ProfileHubRepository) {
        self.repository = repository
    }

    func execute(profile: Profile?, seedItems: [StorefrontItem]) async throws -> ProfileHomeData {
        try await repository.fetchHome(profile: profile, seedItems: seedItems)
    }
}

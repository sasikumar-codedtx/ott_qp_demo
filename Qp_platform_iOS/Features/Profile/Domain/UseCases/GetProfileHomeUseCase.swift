import Foundation

struct GetProfileHomeUseCase {
    private let repository: ProfileHubRepository

    init(repository: ProfileHubRepository) {
        self.repository = repository
    }

    func execute(profileRecommendationID: String) async throws -> ProfileHomeData {
        try await repository.fetchHome(profileRecommendationID: profileRecommendationID)
    }
}

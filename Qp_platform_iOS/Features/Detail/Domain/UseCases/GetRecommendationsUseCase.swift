import Foundation

struct GetRecommendationsUseCase {
    private let repository: ContentDetailRepository

    init(repository: ContentDetailRepository) {
        self.repository = repository
    }

    func execute(itemID: String, contentType: String) async throws -> [StorefrontItem] {
        try await repository.fetchRecommendations(itemID: itemID, contentType: contentType)
    }
}

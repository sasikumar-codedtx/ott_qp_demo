import Foundation

struct GetContentMomentsUseCase {
    private let repository: ContentDetailRepository

    init(repository: ContentDetailRepository) {
        self.repository = repository
    }

    func execute(contentID: String, term: String) async throws -> [StorefrontItem] {
        try await repository.searchMoments(contentID: contentID, term: term)
    }
}

import Foundation

struct GetContentEpisodesUseCase {
    private let repository: ContentDetailRepository

    init(repository: ContentDetailRepository) {
        self.repository = repository
    }

    func execute(seriesID: String) async throws -> [StorefrontItem] {
        try await repository.fetchEpisodes(seriesID: seriesID)
    }
}

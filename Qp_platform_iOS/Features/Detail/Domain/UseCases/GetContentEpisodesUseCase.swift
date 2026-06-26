import Foundation

struct GetContentEpisodesUseCase {
    private let repository: ContentDetailRepository

    init(repository: ContentDetailRepository) {
        self.repository = repository
    }

    func execute(seriesID: String) async throws -> ContentEpisodeBundle {
        try await repository.fetchEpisodeBundle(seriesID: seriesID)
    }

    func execute(seriesID: String, seasonID: String) async throws -> [StorefrontItem] {
        try await repository.fetchEpisodes(seriesID: seriesID, seasonID: seasonID)
    }
}

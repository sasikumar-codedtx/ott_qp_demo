import Foundation

final class ProfileHubRepositoryImpl: ProfileHubRepository {
    private let dataSource: ProfileHubDataSourceProtocol

    init(dataSource: ProfileHubDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func fetchHome(profileRecommendationID: String) async throws -> ProfileHomeData {
        async let continueWatchingResponse = dataSource.fetchContinueWatching()
        async let favoritesResponse = dataSource.fetchFavorites()
        async let recommendationsResponse = dataSource.fetchRecommendations(profileID: profileRecommendationID)

        let (continueWatching, favorites, recommendations) = try await (
            continueWatchingResponse,
            favoritesResponse,
            recommendationsResponse
        )

        return ProfileHomeData(
            continueWatching: continueWatching.data.compactMap { $0.toDomain() },
            favorites: favorites.data.compactMap { $0.toDomain() },
            recommendations: recommendations.data.map { $0.toDomain() }
        )
    }
}

import Foundation

protocol ProfileHubDataSourceProtocol {
    func fetchContinueWatching() async throws -> AuthenticatedContentRailResponseDTO
    func fetchFavorites() async throws -> AuthenticatedContentRailResponseDTO
    func fetchRecommendations(profileID: String) async throws -> RecommendationResponseDTO
}

final class ProfileHubRemoteDataSource: ProfileHubDataSourceProtocol {
    private let apiClient: ProfileHubAPIClient

    init(apiClient: ProfileHubAPIClient) {
        self.apiClient = apiClient
    }

    func fetchContinueWatching() async throws -> AuthenticatedContentRailResponseDTO {
        try await apiClient.fetchContinueWatching()
    }

    func fetchFavorites() async throws -> AuthenticatedContentRailResponseDTO {
        try await apiClient.fetchFavorites()
    }

    func fetchRecommendations(profileID: String) async throws -> RecommendationResponseDTO {
        try await apiClient.fetchRecommendations(profileID: profileID)
    }
}

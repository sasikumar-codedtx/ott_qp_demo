import Foundation

final class ProfileHubAPIClient {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchContinueWatching() async throws -> AuthenticatedContentRailResponseDTO {
        guard let request = ProfileHubRouter.continueWatching.urlRequest else {
            throw AppError.invalidResponse
        }

        let data = try await networkClient.data(for: request)
        return try JSONDecoder().decode(AuthenticatedContentRailResponseDTO.self, from: data)
    }

    func fetchFavorites() async throws -> AuthenticatedContentRailResponseDTO {
        guard let request = ProfileHubRouter.favorites.urlRequest else {
            throw AppError.invalidResponse
        }

        let data = try await networkClient.data(for: request)
        return try JSONDecoder().decode(AuthenticatedContentRailResponseDTO.self, from: data)
    }

    func fetchRecommendations(profileID: String) async throws -> RecommendationResponseDTO {
        guard let request = ProfileHubRouter.recommendations(profileID: profileID).urlRequest else {
            throw AppError.invalidResponse
        }

        let data = try await networkClient.data(for: request)
        return try JSONDecoder().decode(RecommendationResponseDTO.self, from: data)
    }
}

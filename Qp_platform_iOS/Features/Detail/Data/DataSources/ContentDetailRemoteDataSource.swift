import Foundation

protocol ContentDetailDataSourceProtocol {
    func fetchDetail(itemID: String) async throws -> ContentDetailResponseDTO
    func fetchRecommendations(itemID: String, contentType: String) async throws -> RecommendationResponseDTO
    func searchRecommendations(term: String) async throws -> SearchResponseDTO
    func searchMoments(contentID: String, term: String) async throws -> SearchResponseDTO
    func fetchEpisodes(seriesID: String) async throws -> ContentDetailResponseDTO
}

final class ContentDetailRemoteDataSource: ContentDetailDataSourceProtocol {
    private let apiClient: ContentDetailAPIClient

    init(apiClient: ContentDetailAPIClient) {
        self.apiClient = apiClient
    }

    func fetchDetail(itemID: String) async throws -> ContentDetailResponseDTO {
        try await apiClient.fetchDetail(itemID: itemID)
    }

    func fetchRecommendations(itemID: String, contentType: String) async throws -> RecommendationResponseDTO {
        try await apiClient.fetchRecommendations(itemID: itemID, contentType: contentType)
    }

    func searchRecommendations(term: String) async throws -> SearchResponseDTO {
        try await apiClient.searchRecommendations(term: term)
    }

    func searchMoments(contentID: String, term: String) async throws -> SearchResponseDTO {
        try await apiClient.searchMoments(contentID: contentID, term: term)
    }

    func fetchEpisodes(seriesID: String) async throws -> ContentDetailResponseDTO {
        try await apiClient.fetchEpisodes(seriesID: seriesID)
    }
}

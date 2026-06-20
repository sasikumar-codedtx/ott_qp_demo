import Foundation

protocol ContentDetailDataSourceProtocol {
    func fetchDetail(path: String) async throws -> ContentDetailResponseDTO
    func fetchRecommendations(itemID: String, contentType: String) async throws -> RecommendationResponseDTO
}

final class ContentDetailRemoteDataSource: ContentDetailDataSourceProtocol {
    private let apiClient: ContentDetailAPIClient

    init(apiClient: ContentDetailAPIClient) {
        self.apiClient = apiClient
    }

    func fetchDetail(path: String) async throws -> ContentDetailResponseDTO {
        try await apiClient.fetchDetail(path: path)
    }

    func fetchRecommendations(itemID: String, contentType: String) async throws -> RecommendationResponseDTO {
        try await apiClient.fetchRecommendations(itemID: itemID, contentType: contentType)
    }
}

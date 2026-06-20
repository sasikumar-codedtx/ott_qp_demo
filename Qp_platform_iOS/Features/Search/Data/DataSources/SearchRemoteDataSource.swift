import Foundation

protocol SearchDataSourceProtocol {
    func search(term: String) async throws -> SearchResponseDTO
}

final class SearchRemoteDataSource: SearchDataSourceProtocol {
    private let apiClient: SearchAPIClient

    init(apiClient: SearchAPIClient) {
        self.apiClient = apiClient
    }

    func search(term: String) async throws -> SearchResponseDTO {
        try await apiClient.search(term: term)
    }
}

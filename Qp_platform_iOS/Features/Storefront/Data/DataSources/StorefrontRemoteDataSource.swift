import Foundation

protocol StorefrontDataSourceProtocol {
    func fetchLanding(storefrontID: String?, tabID: String?, pageNumber: Int) async throws -> StorefrontResponseDTO
}

final class StorefrontRemoteDataSource: StorefrontDataSourceProtocol {
    private let apiClient: StorefrontAPIClient

    init(apiClient: StorefrontAPIClient) {
        self.apiClient = apiClient
    }

    func fetchLanding(storefrontID: String?, tabID: String?, pageNumber: Int) async throws -> StorefrontResponseDTO {
        try await apiClient.fetchLanding(storefrontID: storefrontID, tabID: tabID, pageNumber: pageNumber)
    }
}

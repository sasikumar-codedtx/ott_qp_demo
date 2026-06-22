import Foundation

protocol StorefrontDataSourceProtocol {
    func fetchStorefront(cohort: QuickplayCohort) async throws -> QuickplayStorefrontResponseDTO
    func fetchStorefront(from url: URL) async throws -> QuickplayStorefrontResponseDTO
    func fetchContent(from url: URL) async throws -> QuickplayContentResponseDTO
    func fetchContentByIDs(cohort: QuickplayCohort, ids: [String], pageNumber: Int, pageSize: Int) async throws -> QuickplayContentResponseDTO
    func fetchCollection(from url: URL) async throws -> QuickplayCollectionResponseDTO
}

final class StorefrontRemoteDataSource: StorefrontDataSourceProtocol {
    private let apiClient: StorefrontAPIClient

    init(apiClient: StorefrontAPIClient) {
        self.apiClient = apiClient
    }

    func fetchStorefront(cohort: QuickplayCohort) async throws -> QuickplayStorefrontResponseDTO {
        try await apiClient.fetchStorefront(cohort: cohort)
    }

    func fetchStorefront(from url: URL) async throws -> QuickplayStorefrontResponseDTO {
        try await apiClient.fetchStorefront(from: url)
    }

    func fetchContent(from url: URL) async throws -> QuickplayContentResponseDTO {
        try await apiClient.fetchContent(from: url)
    }

    func fetchContentByIDs(cohort: QuickplayCohort, ids: [String], pageNumber: Int, pageSize: Int) async throws -> QuickplayContentResponseDTO {
        try await apiClient.fetchContentByIDs(cohort: cohort, ids: ids, pageNumber: pageNumber, pageSize: pageSize)
    }

    func fetchCollection(from url: URL) async throws -> QuickplayCollectionResponseDTO {
        try await apiClient.fetchCollection(from: url)
    }
}

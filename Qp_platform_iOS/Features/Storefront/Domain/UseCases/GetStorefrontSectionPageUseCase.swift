import Foundation

struct GetStorefrontSectionPageUseCase {
    private let repository: StorefrontRepository

    init(repository: StorefrontRepository) {
        self.repository = repository
    }

    func execute(ids: [String], pageNumber: Int, pageSize: Int) async throws -> StorefrontSectionPage {
        try await repository.fetchSectionPage(ids: ids, pageNumber: pageNumber, pageSize: pageSize)
    }

    func execute(sourceURL: URL, pageNumber: Int, pageSize: Int) async throws -> StorefrontSectionPage {
        try await repository.fetchSectionPage(sourceURL: sourceURL, pageNumber: pageNumber, pageSize: pageSize)
    }

    func execute(collection item: StorefrontItem, pageNumber: Int, pageSize: Int) async throws -> StorefrontSectionPage {
        try await repository.fetchCollectionLookupPage(item: item, pageNumber: pageNumber, pageSize: pageSize)
    }
}

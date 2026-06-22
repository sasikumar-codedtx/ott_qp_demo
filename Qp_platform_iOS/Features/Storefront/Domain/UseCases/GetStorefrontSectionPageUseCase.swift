import Foundation

struct GetStorefrontSectionPageUseCase {
    private let repository: StorefrontRepository

    init(repository: StorefrontRepository) {
        self.repository = repository
    }

    func execute(ids: [String], pageNumber: Int, pageSize: Int) async throws -> StorefrontSectionPage {
        try await repository.fetchSectionPage(ids: ids, pageNumber: pageNumber, pageSize: pageSize)
    }
}

import Foundation

struct GetStorefrontPageUseCase {
    private let repository: StorefrontRepository

    init(repository: StorefrontRepository) {
        self.repository = repository
    }

    func execute(storefrontID: String?, tabID: String?, pageNumber: Int) async throws -> StorefrontPage {
        try await repository.fetchLanding(storefrontID: storefrontID, tabID: tabID, pageNumber: pageNumber)
    }
}

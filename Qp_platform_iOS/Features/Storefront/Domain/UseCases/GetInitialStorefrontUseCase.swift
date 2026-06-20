import Foundation

struct GetInitialStorefrontUseCase {
    private let repository: StorefrontRepository

    init(repository: StorefrontRepository) {
        self.repository = repository
    }

    func execute() async throws -> StorefrontPage {
        try await repository.fetchLanding(storefrontID: nil, tabID: nil, pageNumber: 1)
    }
}

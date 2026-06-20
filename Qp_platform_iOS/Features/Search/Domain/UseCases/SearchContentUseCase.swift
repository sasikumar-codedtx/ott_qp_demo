import Foundation

struct SearchContentUseCase {
    private let repository: SearchRepository

    init(repository: SearchRepository) {
        self.repository = repository
    }

    func execute(term: String) async throws -> [StorefrontItem] {
        try await repository.search(term: term)
    }
}

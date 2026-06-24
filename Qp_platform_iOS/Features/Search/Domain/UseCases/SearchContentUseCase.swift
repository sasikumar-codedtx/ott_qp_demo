import Foundation

struct SearchContentUseCase {
    private let repository: SearchRepository

    init(repository: SearchRepository) {
        self.repository = repository
    }

    func execute(term: String, facetTerm: String? = nil) async throws -> SearchResultPage {
        try await repository.search(term: term, facetTerm: facetTerm)
    }
}

import Foundation

struct SearchResultPage {
    let items: [StorefrontItem]
    let filters: [SearchFilter]
}

protocol SearchRepository {
    func search(term: String, facetTerm: String?) async throws -> SearchResultPage
}

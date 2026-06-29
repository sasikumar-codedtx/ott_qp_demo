import Foundation

struct SearchResultPage {
    let items: [StorefrontItem]        // content results (moment=false)
    let momentItems: [StorefrontItem]  // moment results (moment=true)
    let filters: [SearchFilter]
}

protocol SearchRepository {
    func search(term: String, facetTerm: String?) async throws -> SearchResultPage
}

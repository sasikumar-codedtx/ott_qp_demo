import Foundation

final class SearchRepositoryImpl: SearchRepository {
    private let dataSource: SearchDataSourceProtocol
    private let configStore: QuickplayConfigurationStore

    init(dataSource: SearchDataSourceProtocol, configStore: QuickplayConfigurationStore = .shared) {
        self.dataSource = dataSource
        self.configStore = configStore
    }

    func search(term: String, facetTerm: String?) async throws -> SearchResultPage {
        // Moments search (moment=true) is intentionally disabled for now — we don't call that
        // API and return no moment items, so the Moments rail stays hidden in the search view.
        async let contentResponse = dataSource.search(term: term, facetTerm: facetTerm, moment: false)
        let config = await configStore.current()

        let content = try await contentResponse
        let items = content.data.map { $0.toDomain(config: config) }
        let filters = content.facet?.terms?.compactMap { termDTO -> SearchFilter? in
            guard (termDTO.count ?? 0) > 0 else { return nil }
            guard let term = termDTO.term?.trimmingCharacters(in: .whitespacesAndNewlines), !term.isEmpty else { return nil }
            return SearchFilter(id: term, title: term.searchFacetDisplayTitle)
        } ?? []

        return SearchResultPage(items: items, momentItems: [], filters: filters)
    }

}

private extension String {
    var searchFacetDisplayTitle: String {
        split(whereSeparator: { $0 == "-" || $0 == "_" || $0 == " " })
            .map { part in
                let text = String(part)
                return text.prefix(1).uppercased() + text.dropFirst()
            }
            .joined(separator: " ")
    }
}

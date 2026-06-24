import Foundation

final class SearchRepositoryImpl: SearchRepository {
    private let dataSource: SearchDataSourceProtocol
    private let configStore: QuickplayConfigurationStore

    init(dataSource: SearchDataSourceProtocol, configStore: QuickplayConfigurationStore = .shared) {
        self.dataSource = dataSource
        self.configStore = configStore
    }

    func search(term: String, facetTerm: String?) async throws -> SearchResultPage {
        let response = try await dataSource.search(term: term, facetTerm: facetTerm)
        let config = await configStore.current()
        let items = response.data.map { $0.toDomain(config: config) }
        let filters = response.facet?.terms?.compactMap { termDTO -> SearchFilter? in
            guard (termDTO.count ?? 0) > 0 else {
                return nil
            }

            guard let term = termDTO.term?.trimmingCharacters(in: .whitespacesAndNewlines), !term.isEmpty else {
                return nil
            }
            return SearchFilter(id: term, title: term.searchFacetDisplayTitle)
        } ?? []

        return SearchResultPage(items: items, filters: filters)
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

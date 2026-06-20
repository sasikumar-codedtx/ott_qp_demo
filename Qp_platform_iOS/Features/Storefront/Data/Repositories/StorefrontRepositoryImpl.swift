import Foundation

final class StorefrontRepositoryImpl: StorefrontRepository {
    private let dataSource: StorefrontDataSourceProtocol

    init(dataSource: StorefrontDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func fetchLanding(storefrontID: String?, tabID: String?, pageNumber: Int) async throws -> StorefrontPage {
        let response = try await dataSource.fetchLanding(storefrontID: storefrontID, tabID: tabID, pageNumber: pageNumber)

        let tabs = response.data.t.map {
            StorefrontTab(id: $0.id, title: $0.lon?.preferredText ?? "Tab")
        }

        let selectedDTO = response.data.t.first(where: { $0.id == tabID && $0.c != nil }) ?? response.data.t.first(where: { $0.c != nil })
        guard let selectedDTO else {
            throw AppError.invalidResponse
        }

        let sections = (selectedDTO.c ?? []).enumerated().compactMap { index, sectionDTO -> StorefrontSection? in
            let items = (sectionDTO.cd ?? []).map { $0.toDomain() }
            guard !items.isEmpty else { return nil }
            return StorefrontSection(
                id: sectionDTO.id,
                title: (sectionDTO.lon?.preferredText ?? "").nilIfEmpty ?? (index == 0 ? "Hero" : "Section"),
                ratio: sectionDTO.iar ?? "0-2x3",
                items: items,
                isHero: index == 0
            )
        }

        let pagination = selectedDTO.pagination
        let nextPage = pagination.map { (($0.start - 1) / max($0.rows, 1)) + 2 } ?? (pageNumber + 1)
        let loadedCount = pagination.map { $0.start + $0.rows - 1 } ?? sections.count
        let totalCount = pagination?.count ?? sections.count

        return StorefrontPage(
            storefrontID: response.data.id,
            tabs: tabs,
            selectedTabID: selectedDTO.id,
            sections: sections,
            nextPage: nextPage,
            loadedCount: loadedCount,
            totalCount: totalCount
        )
    }
}

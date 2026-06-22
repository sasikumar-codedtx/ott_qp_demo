import Foundation

final class StorefrontRepositoryImpl: StorefrontRepository {
    private let dataSource: StorefrontDataSourceProtocol
    private let configStore: QuickplayConfigurationStore

    init(
        dataSource: StorefrontDataSourceProtocol,
        configStore: QuickplayConfigurationStore = .shared
    ) {
        self.dataSource = dataSource
        self.configStore = configStore
    }

    func fetchLanding(storefrontID: String?, tabID: String?, pageNumber: Int) async throws -> StorefrontPage {
        let requestedCohort = await DemoSessionStore.shared.currentCohort()
        let config = await configStore.current()
        if let customSourceURL = customSourceURL(from: storefrontID) {
            return try await fetchCustomLanding(from: customSourceURL, config: config, cohort: requestedCohort, tabID: tabID)
        }

        if requestedCohort == .entertainment, await DemoSessionStore.shared.prefersMicroDramaTab() {
            guard let microDramaURL = URL(string: AppEnvironment.Endpoint.microDramaStorefrontListURL) else {
                throw AppError.invalidURL
            }
            return try await fetchCustomLanding(from: microDramaURL, config: config, cohort: requestedCohort, tabID: tabID)
        }

        let resolution = try await resolveStorefrontResponse(for: requestedCohort)
        let cohort = resolution.cohort
        let response = resolution.response

        guard let storefront = response.data.first(where: { $0.id == cohort.storefrontID }) ?? response.data.first else {
            throw AppError.invalidResponse
        }

        let tabs = (storefront.t ?? []).map {
            StorefrontTab(id: $0.id, title: $0.lon?.preferredText ?? "Tab")
        }

        let selectedDTO = (storefront.t ?? []).first(where: { $0.id == tabID }) ??
            (storefront.t ?? []).first(where: { $0.lon?.preferredText.caseInsensitiveCompare(AppStrings.Common.home) == .orderedSame }) ??
            storefront.t?.first

        guard let selectedDTO else {
            throw AppError.invalidResponse
        }

        let hydratedSections = try await hydrateSections(containers: selectedDTO.c ?? [], config: config, cohort: cohort)
        let sections = buildSections(from: hydratedSections)

        return StorefrontPage(
            storefrontID: storefront.id,
            tabs: tabs,
            selectedTabID: selectedDTO.id,
            sections: sections,
            nextPage: 1,
            loadedCount: sections.count,
            totalCount: sections.count
        )
    }

    private func resolveStorefrontResponse(for requestedCohort: QuickplayCohort) async throws -> (cohort: QuickplayCohort, response: QuickplayStorefrontResponseDTO) {
        do {
            let response = try await dataSource.fetchStorefront(cohort: requestedCohort)
            if response.data.isEmpty, requestedCohort == .kids {
                let fallbackResponse = try await dataSource.fetchStorefront(cohort: .entertainment)
                return (.entertainment, fallbackResponse)
            }
            return (requestedCohort, response)
        } catch {
            if requestedCohort == .kids {
                let fallbackResponse = try await dataSource.fetchStorefront(cohort: .entertainment)
                return (.entertainment, fallbackResponse)
            }
            throw error
        }
    }

    private func fetchCustomLanding(
        from sourceURL: URL,
        config: QuickplayRuntimeConfig,
        cohort: QuickplayCohort,
        tabID: String?
    ) async throws -> StorefrontPage {
        let response = try await dataSource.fetchStorefront(from: sourceURL)
        guard let storefront = response.data.first else {
            throw AppError.invalidResponse
        }

        let tabs = (storefront.t ?? []).map {
            StorefrontTab(id: $0.id, title: $0.lon?.preferredText ?? "Tab")
        }

        let selectedDTO = (storefront.t ?? []).first(where: { $0.id == tabID }) ??
            (storefront.t ?? []).first(where: { $0.lon?.preferredText.caseInsensitiveCompare(AppStrings.Common.home) == .orderedSame }) ??
            storefront.t?.first

        guard let selectedDTO else {
            throw AppError.invalidResponse
        }

        let hydratedSections = try await hydrateSections(containers: selectedDTO.c ?? [], config: config, cohort: cohort)
        let sections = buildSections(from: hydratedSections)

        return StorefrontPage(
            storefrontID: customStorefrontIdentifier(for: sourceURL),
            tabs: tabs,
            selectedTabID: selectedDTO.id,
            sections: sections,
            nextPage: 1,
            loadedCount: sections.count,
            totalCount: sections.count
        )
    }

    func fetchSectionPage(ids: [String], pageNumber: Int, pageSize: Int) async throws -> StorefrontSectionPage {
        let cohort = await DemoSessionStore.shared.currentCohort()
        let deduplicatedIDs = Array(NSOrderedSet(array: ids)) as? [String] ?? ids
        let startIndex = max((pageNumber - 1) * pageSize, 0)
        let endIndex = min(startIndex + pageSize, deduplicatedIDs.count)

        guard startIndex < endIndex else {
            return StorefrontSectionPage(
                items: [],
                nextPage: pageNumber,
                loadedCount: min(startIndex, deduplicatedIDs.count),
                totalCount: deduplicatedIDs.count
            )
        }

        let pageIDs = Array(deduplicatedIDs[startIndex..<endIndex])
        let response = try await dataSource.fetchContentByIDs(
            cohort: cohort,
            ids: pageIDs,
            pageNumber: pageNumber,
            pageSize: pageSize
        )
        let items = response.data.map { $0.toDomain() }

        return StorefrontSectionPage(
            items: deduplicatedItems(items),
            nextPage: pageNumber + 1,
            loadedCount: endIndex,
            totalCount: deduplicatedIDs.count
        )
    }

    private func hydrateSections(
        containers: [QuickplayContainerDTO],
        config: QuickplayRuntimeConfig,
        cohort: QuickplayCohort
    ) async throws -> [HydratedSection] {
        var sections: [HydratedSection] = []

        for (index, container) in containers.enumerated() {
            let items = try await loadItems(for: container, config: config, cohort: cohort)
            sections.append(
                HydratedSection(
                    id: container.id,
                    title: (container.lon?.preferredText ?? "").nilIfEmpty ?? (index == 0 ? "Featured" : "Section"),
                    ratio: container.preferredRatio,
                    items: items,
                    isHero: container.lo == "banner" || index == 0,
                    sourceType: container.srcType
                )
            )
        }

        return sections
    }

    private func loadItems(
        for container: QuickplayContainerDTO,
        config: QuickplayRuntimeConfig,
        cohort: QuickplayCohort
    ) async throws -> [StorefrontItem] {
        guard let sources = container.i, !sources.isEmpty else { return [] }

        var items: [StorefrontItem] = []
        for source in sources.sorted(by: { ($0.priority ?? 0) < ($1.priority ?? 0) }) {
            guard let url = source.normalizedURL(config: config, cohort: cohort) else { continue }
            switch source.type {
            case "collection":
                let response = try await dataSource.fetchCollection(from: url)
                items.append(contentsOf: response.data.map { $0.toDomain() })
            default:
                let response = try await dataSource.fetchContent(from: url)
                items.append(contentsOf: response.data.map { $0.toDomain() })
            }
        }

        return deduplicatedItems(items)
    }

    private func buildSections(from hydratedSections: [HydratedSection]) -> [StorefrontSection] {
        let library = deduplicatedItems(
            hydratedSections
                .filter { $0.sourceType == nil }
                .flatMap { $0.items }
        )

        return hydratedSections.compactMap { section -> StorefrontSection? in
            let resolvedItems: [StorefrontItem]
            switch section.sourceType {
            case "continue_watching":
                resolvedItems = DemoRailComposer.continueWatching(from: library)
            case "favorite":
                resolvedItems = DemoRailComposer.favorites(from: library)
            default:
                resolvedItems = section.items
            }

            guard !resolvedItems.isEmpty else { return nil }
            return StorefrontSection(
                id: section.id,
                title: section.title,
                ratio: section.ratio,
                items: resolvedItems,
                isHero: section.isHero
            )
        }
    }

    private func deduplicatedItems(_ items: [StorefrontItem]) -> [StorefrontItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }

    private func customStorefrontIdentifier(for url: URL) -> String {
        "custom:\(url.absoluteString)"
    }

    private func customSourceURL(from storefrontID: String?) -> URL? {
        guard let storefrontID, storefrontID.hasPrefix("custom:") else { return nil }
        let value = String(storefrontID.dropFirst("custom:".count))
        return URL(string: value)
    }
}

private struct HydratedSection {
    let id: String
    let title: String
    let ratio: String
    let items: [StorefrontItem]
    let isHero: Bool
    let sourceType: String?
}

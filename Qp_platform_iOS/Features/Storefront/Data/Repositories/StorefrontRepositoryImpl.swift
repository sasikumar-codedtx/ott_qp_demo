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
        StorefrontDebugLogger.logFetchStart(
            requestedCohort: requestedCohort,
            storefrontID: storefrontID,
            tabID: tabID,
            pageNumber: pageNumber
        )

        if let customSourceURL = customSourceURL(from: storefrontID) {
            StorefrontDebugLogger.log("Using custom storefront source: \(customSourceURL.absoluteString)")
            return try await fetchCustomLanding(from: customSourceURL, config: config, cohort: requestedCohort, tabID: tabID)
        }

        let resolution = try await resolveStorefrontResponse(for: requestedCohort)
        let cohort = resolution.cohort
        let response = resolution.response
        StorefrontDebugLogger.logResponseIDs(response, cohort: cohort)

        let exactStorefront = response.data.first(where: { $0.id == cohort.storefrontID })
        if exactStorefront == nil, !response.data.isEmpty {
            StorefrontDebugLogger.log(
                "Expected storefront ID not found. Falling back to first storefront. expected=\(cohort.storefrontID)"
            )
        }

        guard let storefront = exactStorefront ?? response.data.first else {
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
        StorefrontDebugLogger.logSelectedStorefront(
            storefrontID: storefront.id,
            requestedTabID: tabID,
            selectedTabID: selectedDTO.id,
            selectedTabTitle: selectedDTO.lon?.preferredText,
            tabs: tabs,
            containerCount: selectedDTO.c?.count ?? 0
        )

        let hydratedSections = try await hydrateSections(containers: selectedDTO.c ?? [], config: config, cohort: cohort)
        let sections = await buildSections(from: hydratedSections)
        StorefrontDebugLogger.logBuiltSections(sections)

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
            StorefrontDebugLogger.log(
                "Fetching storefront list for cohort=\(requestedCohort.rawValue), title=\(requestedCohort.title), expectedID=\(requestedCohort.storefrontID), pf=\(requestedCohort.profileFlag)"
            )
            let response = try await dataSource.fetchStorefront(cohort: requestedCohort)
            if response.data.isEmpty, requestedCohort == .kids {
                StorefrontDebugLogger.log("Kids storefront response was empty. Falling back to Entertainment.")
                let fallbackResponse = try await dataSource.fetchStorefront(cohort: .entertainment)
                return (.entertainment, fallbackResponse)
            }
            return (requestedCohort, response)
        } catch {
            if requestedCohort == .kids {
                StorefrontDebugLogger.log("Kids storefront fetch failed: \(error.localizedDescription). Falling back to Entertainment.")
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
        StorefrontDebugLogger.logResponseIDs(response, cohort: cohort)

        let tabs = (storefront.t ?? []).map {
            StorefrontTab(id: $0.id, title: $0.lon?.preferredText ?? "Tab")
        }

        let selectedDTO = (storefront.t ?? []).first(where: { $0.id == tabID }) ??
            (storefront.t ?? []).first(where: { $0.lon?.preferredText.caseInsensitiveCompare(AppStrings.Common.home) == .orderedSame }) ??
            storefront.t?.first

        guard let selectedDTO else {
            throw AppError.invalidResponse
        }
        StorefrontDebugLogger.logSelectedStorefront(
            storefrontID: storefront.id,
            requestedTabID: tabID,
            selectedTabID: selectedDTO.id,
            selectedTabTitle: selectedDTO.lon?.preferredText,
            tabs: tabs,
            containerCount: selectedDTO.c?.count ?? 0
        )

        let hydratedSections = try await hydrateSections(containers: selectedDTO.c ?? [], config: config, cohort: cohort)
        let sections = await buildSections(from: hydratedSections)
        StorefrontDebugLogger.logBuiltSections(sections)

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
        StorefrontDebugLogger.log(
            "Fetch section page cohort=\(cohort.rawValue), page=\(pageNumber), pageSize=\(pageSize), requestedIDs=\(ids.count), dedupedIDs=\(deduplicatedIDs.count)"
        )

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
        let config = await configStore.current()
        let items = response.data.map { $0.toDomain(config: config) }

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
            StorefrontDebugLogger.log(
                "Hydrating container[\(index)] id=\(container.id), title=\(container.lon?.preferredText ?? "<empty>"), ratio=\(container.preferredRatio), layout=\(container.lo ?? "<nil>"), sourceType=\(container.srcType ?? "<nil>")"
            )
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
            StorefrontDebugLogger.log(
                "Loading source type=\(source.type ?? "<nil>"), priority=\(source.priority ?? 0), url=\(url.absoluteString)"
            )
            switch source.type {
            case "collection":
                let response = try await dataSource.fetchCollection(from: url)
                items.append(contentsOf: response.data.map { $0.toDomain(config: config) })
            default:
                let response = try await dataSource.fetchContent(from: url)
                items.append(contentsOf: response.data.map { $0.toDomain(config: config) })
            }
        }

        return deduplicatedItems(items)
    }

    private func buildSections(from hydratedSections: [HydratedSection]) async -> [StorefrontSection] {
        let library = deduplicatedItems(
            hydratedSections
                .filter { $0.sourceType == nil }
                .flatMap { $0.items }
        )
        let continueWatchingItems = await DemoSessionStore.shared.continueWatchingItems(limit: 10)

        return hydratedSections.compactMap { section -> StorefrontSection? in
            let resolvedItems: [StorefrontItem]
            let sectionKey = "\(section.sourceType ?? "") \(section.id) \(section.title)"
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")

            if sectionKey.contains("continue_watching") || sectionKey.contains("continuewatching") {
                resolvedItems = DemoRailComposer.continueWatching(from: continueWatchingItems)
            } else if section.sourceType == "favorite" {
                resolvedItems = DemoRailComposer.favorites(from: library)
            } else {
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

private enum StorefrontDebugLogger {
    static func logFetchStart(
        requestedCohort: QuickplayCohort,
        storefrontID: String?,
        tabID: String?,
        pageNumber: Int
    ) {
        log(
            "Fetch landing requestedCohort=\(requestedCohort.rawValue), title=\(requestedCohort.title), expectedStorefrontID=\(requestedCohort.storefrontID), pf=\(requestedCohort.profileFlag), incomingStorefrontID=\(storefrontID ?? "<nil>"), tabID=\(tabID ?? "<nil>"), page=\(pageNumber)"
        )
    }

    static func logResponseIDs(_ response: QuickplayStorefrontResponseDTO, cohort: QuickplayCohort) {
        let ids = response.data.map(\.id)
        log(
            "Storefront list response cohort=\(cohort.rawValue), expectedID=\(cohort.storefrontID), availableIDs=\(ids)"
        )
    }

    static func logSelectedStorefront(
        storefrontID: String,
        requestedTabID: String?,
        selectedTabID: String,
        selectedTabTitle: String?,
        tabs: [StorefrontTab],
        containerCount: Int
    ) {
        let tabSummary = tabs.map { "\($0.title)(\($0.id))" }
        log(
            "Selected storefrontID=\(storefrontID), requestedTabID=\(requestedTabID ?? "<nil>"), selectedTab=\(selectedTabTitle ?? "Tab")(\(selectedTabID)), tabCount=\(tabs.count), tabs=\(tabSummary), selectedContainerCount=\(containerCount)"
        )
    }

    static func logBuiltSections(_ sections: [StorefrontSection]) {
        let sectionSummary = sections.map { "\($0.title)(items=\($0.items.count), ratio=\($0.ratio), hero=\($0.isHero))" }
        log("Built sections count=\(sections.count), sections=\(sectionSummary)")
    }

    static func log(_ message: String) {
        print("[Storefront] \(message)")
    }
}

import Foundation

final class StorefrontRepositoryImpl: StorefrontRepository {
    private let dataSource: StorefrontDataSourceProtocol
    private let configStore: QuickplayConfigurationStore
    private let landingPageSize = 5

    // landingscreen is called once per cohort. Tab switches call landingscreen again with sfid + tid.
    private var manifestByCohort: [QuickplayCohort: StorefrontManifest] = [:]

    init(
        dataSource: StorefrontDataSourceProtocol,
        configStore: QuickplayConfigurationStore = .shared
    ) {
        self.dataSource = dataSource
        self.configStore = configStore
    }

    func fetchLanding(storefrontID: String?, tabID: String?, pageNumber: Int) async throws -> StorefrontPage {
        let cohort = await DemoSessionStore.shared.currentCohort()
        let config = await configStore.current()
        StorefrontDebugLogger.logFetchStart(requestedCohort: cohort, storefrontID: storefrontID, tabID: tabID, pageNumber: pageNumber)

        if let customSourceURL = customSourceURL(from: storefrontID) {
            StorefrontDebugLogger.log("Using custom storefront source: \(customSourceURL.absoluteString)")
            return try await fetchCustomLanding(from: customSourceURL, config: config, cohort: cohort, tabID: tabID)
        }

        let manifest = try await resolveManifest(for: cohort)
        let selectedTab = manifest.tabs.first(where: { $0.id == tabID })
            ?? manifest.tabs.first(where: { $0.title.caseInsensitiveCompare(AppStrings.Common.home) == .orderedSame })
            ?? manifest.tabs.first

        guard let selectedTab else {
            throw AppError.invalidResponse
        }

        StorefrontDebugLogger.log(
            "cohort=\(cohort.rawValue) storefrontID=\(manifest.storefrontID) selectedTab=\(selectedTab.title)(\(selectedTab.id))"
        )

        let containers: [QuickplayContainerDTO]
        if tabID == nil, let initialContainers = manifest.initialContainers {
            containers = initialContainers
            StorefrontDebugLogger.log("Using initial landingscreen containers \(containers.count) for tab=\(selectedTab.title)")
        } else {
            let containersResponse = try await dataSource.fetchContainers(
                cohort: cohort,
                storefrontID: manifest.storefrontID,
                tabID: selectedTab.id,
                pageNumber: pageNumber,
                pageSize: landingPageSize
            )
            containers = containersResponse.data
            StorefrontDebugLogger.log("Landingscreen tab returned \(containers.count) containers for tab=\(selectedTab.title)")
        }

        let hydratedSections = try await hydrateSections(containers: containers, config: config, cohort: cohort)
        let sections = await buildSections(from: hydratedSections)
        StorefrontDebugLogger.logBuiltSections(sections)

        return StorefrontPage(
            storefrontID: manifest.storefrontID,
            tabs: manifest.tabs,
            selectedTabID: selectedTab.id,
            sections: sections,
            nextPage: pageNumber + 1,
            loadedCount: sections.count,
            totalCount: sections.count,
            hasMore: !sections.isEmpty
        )
    }

    // Calls landingscreen for the cohort if we haven't done so yet, then caches storefront id, tabs, and first tab containers.
    private func resolveManifest(for cohort: QuickplayCohort) async throws -> StorefrontManifest {
        if let cached = manifestByCohort[cohort] {
            StorefrontDebugLogger.log("Manifest cache hit cohort=\(cohort.rawValue) storefrontID=\(cached.storefrontID)")
            return cached
        }

        StorefrontDebugLogger.log("Fetching landingscreen cohort=\(cohort.rawValue) pf=\(cohort.profileFlag)")
        let response = try await fetchLandingScreenWithFallback(for: cohort)

        guard let storefront = response.data.first else {
            throw AppError.invalidResponse
        }

        let tabs = (storefront.t ?? []).map {
            StorefrontTab(id: $0.id, title: $0.lon?.preferredText ?? "Tab")
        }

        let initialContainers = storefront.t?.first(where: { ($0.c ?? []).isEmpty == false })?.c
        let manifest = StorefrontManifest(storefrontID: storefront.id, tabs: tabs, initialContainers: initialContainers)
        manifestByCohort[cohort] = manifest

        StorefrontDebugLogger.log(
            "Stored manifest cohort=\(cohort.rawValue) storefrontID=\(storefront.id) tabs=\(tabs.map { "\($0.title)(\($0.id))" })"
        )
        return manifest
    }

    private func fetchLandingScreenWithFallback(for requestedCohort: QuickplayCohort) async throws -> QuickplayStorefrontResponseDTO {
        do {
            let response = try await dataSource.fetchStorefront(cohort: requestedCohort)
            if !response.data.isEmpty {
                return response
            }
            StorefrontDebugLogger.log("\(requestedCohort.title) landingscreen empty, falling back to entertainment")
        } catch {
            guard requestedCohort != .entertainment else { throw error }
            StorefrontDebugLogger.log("\(requestedCohort.title) landingscreen failed: \(error.localizedDescription), falling back to entertainment")
        }
        return try await dataSource.fetchStorefront(cohort: .entertainment)
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

        let selectedTab = tabs.first(where: { $0.id == tabID })
            ?? tabs.first(where: { $0.title.caseInsensitiveCompare(AppStrings.Common.home) == .orderedSame })
            ?? tabs.first

        guard let selectedTab else {
            throw AppError.invalidResponse
        }

        let containersResponse = try await dataSource.fetchContainers(
            cohort: cohort,
            storefrontID: storefront.id,
            tabID: selectedTab.id,
            pageNumber: 1,
            pageSize: 100
        )

        let hydratedSections = try await hydrateSections(containers: containersResponse.data, config: config, cohort: cohort)
        let sections = await buildSections(from: hydratedSections)

        return StorefrontPage(
            storefrontID: customStorefrontIdentifier(for: sourceURL),
            tabs: tabs,
            selectedTabID: selectedTab.id,
            sections: sections,
            nextPage: 2,
            loadedCount: sections.count,
            totalCount: sections.count,
            hasMore: false
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
        let firstBannerContainerID = containers.first(where: { $0.lo == "banner" })?.id

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
                    isHero: container.id == firstBannerContainerID,
                    sourceType: container.srcType,
                    backgroundImageURL: container.backgroundImageURL(config: config)
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
        if let embeddedItems = container.cd, !embeddedItems.isEmpty {
            StorefrontDebugLogger.log("Using embedded cd[] id=\(container.id), count=\(embeddedItems.count)")
            return deduplicatedItems(embeddedItems.map { $0.toDomain(config: config) })
        }

        guard let sources = container.i, !sources.isEmpty else { return [] }

        var items: [StorefrontItem] = []
        for source in sources.sorted(by: { ($0.priority ?? 0) < ($1.priority ?? 0) }) {
            guard let url = source.normalizedURL(config: config, cohort: cohort) else { continue }
            StorefrontDebugLogger.log("Loading source type=\(source.type ?? "<nil>"), url=\(url.absoluteString)")
            do {
                switch source.type {
                case "collection":
                    let response = try await dataSource.fetchCollection(from: url)
                    items.append(contentsOf: response.data.map { $0.toDomain(config: config) })
                default:
                    let response = try await dataSource.fetchContent(from: url)
                    items.append(contentsOf: response.data.map { $0.toDomain(config: config) })
                }
            } catch {
                StorefrontDebugLogger.log("Skipping source container=\(container.id), error=\(error.localizedDescription)")
            }
        }

        return deduplicatedItems(items)
    }

    private func buildSections(from hydratedSections: [HydratedSection]) async -> [StorefrontSection] {
        let library = deduplicatedItems(
            hydratedSections.filter { $0.sourceType == nil }.flatMap { $0.items }
        )
        let continueWatchingItems = await DemoSessionStore.shared.continueWatchingItems(limit: 10)

        return hydratedSections.compactMap { section -> StorefrontSection? in
            let resolvedItems: [StorefrontItem]
            let sectionKey = "\(section.sourceType ?? "") \(section.id) \(section.title)"
                .lowercased().replacingOccurrences(of: " ", with: "_")

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
                isHero: section.isHero,
                backgroundImageURL: section.backgroundImageURL
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

private struct StorefrontManifest {
    let storefrontID: String
    let tabs: [StorefrontTab]
    let initialContainers: [QuickplayContainerDTO]?
}

private struct HydratedSection {
    let id: String
    let title: String
    let ratio: String
    let items: [StorefrontItem]
    let isHero: Bool
    let sourceType: String?
    let backgroundImageURL: URL?
}

private enum StorefrontDebugLogger {
    static func logFetchStart(
        requestedCohort: QuickplayCohort,
        storefrontID: String?,
        tabID: String?,
        pageNumber: Int
    ) {
        log(
            "Fetch landing requestedCohort=\(requestedCohort.rawValue), title=\(requestedCohort.title), pf=\(requestedCohort.profileFlag), incomingStorefrontID=\(storefrontID ?? "<nil>"), tabID=\(tabID ?? "<nil>"), page=\(pageNumber)"
        )
    }

    static func logResponseIDs(_ response: QuickplayStorefrontResponseDTO, cohort: QuickplayCohort) {
        let ids = response.data.map(\.id)
        log("Landingscreen response cohort=\(cohort.rawValue), pf=\(cohort.profileFlag), returnedIDs=\(ids)")
    }

    static func logBuiltSections(_ sections: [StorefrontSection]) {
        let sectionSummary = sections.map { "\($0.title)(items=\($0.items.count), ratio=\($0.ratio), hero=\($0.isHero))" }
        log("Built sections count=\(sections.count), sections=\(sectionSummary)")
    }

    static func log(_ message: String) {
        print("[Storefront] \(message)")
    }
}

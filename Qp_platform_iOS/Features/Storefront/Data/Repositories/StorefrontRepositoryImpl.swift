import Foundation

final class StorefrontRepositoryImpl: StorefrontRepository {
    private let dataSource: StorefrontDataSourceProtocol
    private let configStore: QuickplayConfigurationStore
    private let landingPageSize = 50

    // Initial landingscreen calls always start without sfid/tid. Subsequent tab/page calls reuse
    // the storefront id returned by that response and pass it back with the selected tab id.
    private var manifestByStorefrontID: [String: StorefrontManifest] = [:]

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

        let manifest: StorefrontManifest
        let selectedTab: StorefrontTab
        let containers: [QuickplayContainerDTO]

        if storefrontID == nil, tabID == nil {
            let freshManifest = try await fetchFreshManifest(for: cohort)
            guard let firstTab = freshManifest.tabs.first else {
                throw AppError.invalidResponse
            }

            manifest = freshManifest
            selectedTab = firstTab
            let containersResponse = try await dataSource.fetchContainers(
                cohort: cohort,
                storefrontID: freshManifest.storefrontID,
                tabID: firstTab.id,
                pageNumber: 1,
                pageSize: landingPageSize
            )
            containers = containersResponse.data
        } else {
            guard let storefrontID else {
                throw AppError.invalidResponse
            }

            let cachedManifest = manifestByStorefrontID[storefrontID]
            let selected = cachedManifest?.tabs.first(where: { $0.id == tabID })
                ?? cachedManifest?.tabs.first
                ?? StorefrontTab(id: tabID ?? "", title: "Tab")

            guard selected.id.isEmpty == false else {
                throw AppError.invalidResponse
            }

            manifest = cachedManifest ?? StorefrontManifest(storefrontID: storefrontID, tabs: [selected], initialContainers: nil)
            selectedTab = selected
            let containersResponse = try await dataSource.fetchContainers(
                cohort: cohort,
                storefrontID: storefrontID,
                tabID: selectedTab.id,
                pageNumber: pageNumber,
                pageSize: landingPageSize
            )
            containers = containersResponse.data
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

    // Always fresh-fetches the first landingscreen for launch/profile changes. The response data
    // object provides the storefront id and its first tab becomes the selected tab.
    private func fetchFreshManifest(for cohort: QuickplayCohort) async throws -> StorefrontManifest {
        let response = try await fetchLandingScreenWithFallback(for: cohort)

        guard let storefront = response.data.first else {
            throw AppError.invalidResponse
        }

        let tabs = (storefront.t ?? []).map {
            StorefrontTab(id: $0.id, title: $0.lon?.preferredText ?? "Tab")
        }

        let initialContainers = storefront.t?.first?.c
        let manifest = StorefrontManifest(storefrontID: storefront.id, tabs: tabs, initialContainers: initialContainers)
        manifestByStorefrontID[storefront.id] = manifest
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

    func fetchCollectionLookupPage(item: StorefrontItem, pageNumber: Int, pageSize: Int) async throws -> StorefrontSectionPage {
        let cohort = await DemoSessionStore.shared.currentCohort()
        StorefrontDebugLogger.log(
            "Fetch collection lookup cohort=\(cohort.rawValue), item=\(item.title), id=\(item.id), cardType=\(item.cardType ?? "<nil>"), cust_sc=\(item.customSearchCategory ?? "<nil>"), page=\(pageNumber), pageSize=\(pageSize)"
        )

        let response = try await dataSource.fetchCollectionLookup(
            cohort: cohort,
            item: item,
            pageNumber: pageNumber,
            pageSize: pageSize
        )
        let config = await configStore.current()
        let items = deduplicatedItems(response.data.map { $0.toDomain(config: config) })
        let loadedCount: Int
        let totalCount: Int
        if let start = response.header.start,
           let rows = response.header.rows,
           let count = response.header.count {
            loadedCount = min(start + rows, count)
            totalCount = count
        } else {
            loadedCount = ((pageNumber - 1) * pageSize) + items.count
            totalCount = items.isEmpty ? loadedCount : loadedCount + 1
        }

        return StorefrontSectionPage(
            items: items,
            nextPage: pageNumber + 1,
            loadedCount: loadedCount,
            totalCount: totalCount
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
            let backgroundImageURL = container.backgroundImageURL(config: config)
            sections.append(
                HydratedSection(
                    id: container.id,
                    title: (container.lon?.preferredText ?? "").nilIfEmpty ?? (index == 0 ? "Featured" : "Section"),
                    ratio: container.preferredRatio,
                    items: items,
                    isHero: container.id == firstBannerContainerID,
                    sourceType: container.srcType,
                    backgroundImageURL: backgroundImageURL,
                    backgroundColorHex: backgroundImageURL == nil ? nil : container.backgroundColorHex,
                    viewAllContentIDs: contentIDs(from: container.i)
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

        return []
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
                backgroundImageURL: section.backgroundImageURL,
                backgroundColorHex: section.backgroundColorHex,
                viewAllContentIDs: section.viewAllContentIDs
            )
        }
    }

    private func contentIDs(from sources: [QuickplayContentSourceDTO]?) -> [String]? {
        let stripSet = CharacterSet.whitespacesAndNewlines.union(.init(charactersIn: "\"'"))
        let ids = sources?
            .flatMap { source in
                (source.q ?? "")
                    .split(separator: ",")
                    .map { String($0).trimmingCharacters(in: stripSet) }
                    .filter { !$0.isEmpty }
            } ?? []
        return ids.isEmpty ? nil : Array(NSOrderedSet(array: ids)) as? [String] ?? ids
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
    let backgroundColorHex: String?
    let viewAllContentIDs: [String]?
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

    static func log(_: String) {
    }
}

import Combine
import Foundation

@MainActor
final class StorefrontSectionBrowseViewModel: ObservableObject {
    @Published private(set) var section: StorefrontSection?
    @Published private(set) var cohort: QuickplayCohort = .entertainment
    @Published private(set) var items: [StorefrontItem] = []
    @Published private(set) var isInitialLoading = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isAwaitingInitialLoad = false

    private let useCase: GetStorefrontSectionPageUseCase
    private let pageSize = Int(AppEnvironment.Quickplay.storefrontPageSize) ?? 20
    private var currentIDs: [String] = []
    private var source: BrowseSource?
    private var currentCacheKey: String?
    private var cache: [String: StorefrontSectionPage] = [:]

    init(useCase: GetStorefrontSectionPageUseCase) {
        self.useCase = useCase
    }

    var title: String {
        section?.title ?? ""
    }

    var loadIdentity: String {
        currentCacheKey ?? title
    }

    var shouldShowInitialSkeleton: Bool {
        items.isEmpty && (isInitialLoading || isAwaitingInitialLoad)
    }

    var isRecommendedSection: Bool {
        guard let section else { return false }
        let source = "\(section.id) \(section.title)".lowercased()
        return source.contains("recommended") ||
            source.contains("recommendation") ||
            source.contains("more like") ||
            source.contains("because you watched")
    }

    var recommendationFilterTitles: [String] {
        let dynamicTitles = items
            .flatMap { item -> [String] in
                var values = item.genres
                if !item.contentType.isEmpty {
                    values.append(item.contentType.capitalized)
                }
                return values
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, title in
                if result.contains(where: { $0.caseInsensitiveCompare(title) == .orderedSame }) == false {
                    result.append(title)
                }
            }

        return ["All"] + Array(dynamicTitles.prefix(5))
    }

    func present(section: StorefrontSection, cohort: QuickplayCohort) {
        self.section = section
        self.cohort = cohort
        currentIDs = deduplicatedIDs(from: section.items)
        source = .sectionIDs(currentIDs)
        currentCacheKey = "\(section.id)-\(cohort.rawValue)-\(section.ratio)"
        errorMessage = nil

        if let cached = currentCache {
            items = cached.items
            isAwaitingInitialLoad = false
        } else {
            items = []
            isAwaitingInitialLoad = true
        }
    }

    func present(collection item: StorefrontItem, cohort: QuickplayCohort) {
        let preferredRatio = item.availableRatios.first(where: { ratio in
            ratio == "0-16x9" || ratio == "0-2x3" || ratio == "0-9x16"
        }) ?? item.availableRatios.first ?? "0-2x3"
        let section = StorefrontSection(
            id: item.id,
            title: item.title,
            ratio: preferredRatio,
            items: [],
            isHero: false
        )
        self.section = section
        self.cohort = cohort
        currentIDs = []
        source = .collectionLookup(item)
        currentCacheKey = "collection-\(item.id)-\(cohort.rawValue)-\(item.customSearchCategory ?? item.title)"
        errorMessage = nil

        if let cached = currentCache {
            items = cached.items
            isAwaitingInitialLoad = false
        } else {
            items = []
            isAwaitingInitialLoad = true
        }
    }

    func loadIfNeeded() async {
        await refresh()
    }

    func loadAfterPushAnimationIfNeeded() async {
        if isAwaitingInitialLoad {
            try? await Task.sleep(for: .seconds(1))
        }
        await loadIfNeeded()
    }

    func loadMoreIfNeeded(currentItem item: StorefrontItem) async {
        guard item.id == items.last?.id else { return }
        guard let cache = currentCache, cache.hasMore else { return }
        guard !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await fetchPage(pageNumber: cache.nextPage)
            let combinedItems = deduplicated(items + page.items)
            let merged = StorefrontSectionPage(
                items: combinedItems,
                nextPage: page.nextPage,
                loadedCount: combinedItems.count,
                totalCount: page.totalCount
            )
            items = combinedItems
            storeCurrentCache(merged)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refresh() async {
        guard source != nil else { return }
        isAwaitingInitialLoad = false

        if items.isEmpty {
            isInitialLoading = true
        } else {
            isRefreshing = true
        }

        defer {
            isInitialLoading = false
            isRefreshing = false
        }

        do {
            let page = try await fetchPage(pageNumber: 1)
            items = page.items
            storeCurrentCache(page)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchPage(pageNumber: Int) async throws -> StorefrontSectionPage {
        switch source {
        case .sectionIDs(let ids):
            guard !ids.isEmpty else {
                return StorefrontSectionPage(items: [], nextPage: pageNumber, loadedCount: 0, totalCount: 0)
            }
            return try await useCase.execute(ids: ids, pageNumber: pageNumber, pageSize: pageSize)
        case .collectionLookup(let item):
            return try await useCase.execute(collection: item, pageNumber: pageNumber, pageSize: pageSize)
        case nil:
            return StorefrontSectionPage(items: [], nextPage: pageNumber, loadedCount: 0, totalCount: 0)
        }
    }

    private var currentCache: StorefrontSectionPage? {
        guard let currentCacheKey else { return nil }
        return cache[currentCacheKey]
    }

    private func storeCurrentCache(_ page: StorefrontSectionPage) {
        guard let currentCacheKey else { return }
        cache[currentCacheKey] = page
    }

    private func deduplicatedIDs(from items: [StorefrontItem]) -> [String] {
        var seen = Set<String>()
        return items.compactMap { item in
            guard seen.insert(item.id).inserted else { return nil }
            return item.id
        }
    }

    private func deduplicated(_ items: [StorefrontItem]) -> [StorefrontItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }
}

private enum BrowseSource {
    case sectionIDs([String])
    case collectionLookup(StorefrontItem)
}

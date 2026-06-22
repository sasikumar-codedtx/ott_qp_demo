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

    private let useCase: GetStorefrontSectionPageUseCase
    private let pageSize = Int(AppEnvironment.Quickplay.storefrontPageSize) ?? 20
    private var currentIDs: [String] = []
    private var currentCacheKey: String?
    private var cache: [String: StorefrontSectionPage] = [:]

    init(useCase: GetStorefrontSectionPageUseCase) {
        self.useCase = useCase
    }

    var title: String {
        section?.title ?? ""
    }

    func present(section: StorefrontSection, cohort: QuickplayCohort) {
        self.section = section
        self.cohort = cohort
        currentIDs = deduplicatedIDs(from: section.items)
        currentCacheKey = "\(section.id)-\(cohort.rawValue)-\(section.ratio)"
        errorMessage = nil

        if let cached = currentCache {
            items = cached.items
        } else {
            items = Array(section.items.prefix(pageSize))
        }
    }

    func loadIfNeeded() async {
        await refresh()
    }

    func loadMoreIfNeeded(currentItem item: StorefrontItem) async {
        guard item.id == items.last?.id else { return }
        guard let cache = currentCache, cache.hasMore else { return }
        guard !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await useCase.execute(ids: currentIDs, pageNumber: cache.nextPage, pageSize: pageSize)
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
        guard !currentIDs.isEmpty else { return }

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
            let page = try await useCase.execute(ids: currentIDs, pageNumber: 1, pageSize: pageSize)
            items = page.items
            storeCurrentCache(page)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
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

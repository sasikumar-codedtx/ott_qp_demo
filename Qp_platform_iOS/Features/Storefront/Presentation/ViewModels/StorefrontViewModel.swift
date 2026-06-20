import Combine
import Foundation

@MainActor
final class StorefrontViewModel: ObservableObject {
    @Published private(set) var tabs: [StorefrontTab] = []
    @Published private(set) var selectedTabID: String?
    @Published private(set) var sections: [StorefrontSection] = []
    @Published private(set) var isInitialLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?

    private let initialUseCase: GetInitialStorefrontUseCase
    private let pageUseCase: GetStorefrontPageUseCase
    private var storefrontID: String?
    private var tabCache: [String: StorefrontPage] = [:]

    init(initialUseCase: GetInitialStorefrontUseCase, pageUseCase: GetStorefrontPageUseCase) {
        self.initialUseCase = initialUseCase
        self.pageUseCase = pageUseCase
    }

    var selectedTabTitle: String {
        tabs.first(where: { $0.id == selectedTabID })?.title ?? AppStrings.Common.home
    }

    var searchSeedItems: [StorefrontItem] {
        let sourceSections = sections.isEmpty ? tabCache.values.flatMap(\.sections) : sections
        var seen = Set<String>()
        return sourceSections.flatMap(\.items).filter { seen.insert($0.id).inserted }
    }

    func loadInitialIfNeeded() async {
        guard tabs.isEmpty, !isInitialLoading else { return }
        await load(storefrontID: nil, tabID: nil, pageNumber: 1, append: false)
    }

    func selectTab(_ tab: StorefrontTab) async {
        guard selectedTabID != tab.id || sections.isEmpty else { return }

        if let cached = tabCache[tab.id] {
            selectedTabID = cached.selectedTabID
            sections = cached.sections
            errorMessage = nil
            return
        }

        await load(storefrontID: storefrontID, tabID: tab.id, pageNumber: 1, append: false)
    }

    func selectHomeTabIfNeeded() async {
        guard let tab = tabs.first(where: { $0.title.caseInsensitiveCompare(AppStrings.Common.home) == .orderedSame }) ?? tabs.first else {
            return
        }
        await selectTab(tab)
    }

    func selectHotTabIfNeeded() async {
        guard let tab = tabs.first(where: { $0.title.caseInsensitiveCompare(AppStrings.Common.home) != .orderedSame }) ?? tabs.first else {
            return
        }
        await selectTab(tab)
    }

    func loadMoreIfNeeded(currentSectionID: String) async {
        guard
            let selectedTabID,
            let cache = tabCache[selectedTabID],
            !isLoadingMore,
            cache.hasMore,
            cache.sections.last?.id == currentSectionID
        else {
            return
        }

        await load(
            storefrontID: storefrontID,
            tabID: selectedTabID,
            pageNumber: cache.nextPage,
            append: true
        )
    }

    private func load(storefrontID: String?, tabID: String?, pageNumber: Int, append: Bool) async {
        if append {
            isLoadingMore = true
        } else {
            isInitialLoading = true
        }

        defer {
            isInitialLoading = false
            isLoadingMore = false
        }

        do {
            let page: StorefrontPage
            if append {
                page = try await pageUseCase.execute(storefrontID: storefrontID, tabID: tabID, pageNumber: pageNumber)
            } else if storefrontID == nil && tabID == nil {
                page = try await initialUseCase.execute()
            } else {
                page = try await pageUseCase.execute(storefrontID: storefrontID, tabID: tabID, pageNumber: pageNumber)
            }

            self.storefrontID = page.storefrontID
            tabs = page.tabs

            let combinedSections: [StorefrontSection]
            if append, let cached = tabCache[page.selectedTabID] {
                combinedSections = deduplicatedSections(cached.sections + page.sections)
            } else {
                combinedSections = page.sections
            }

            let mergedPage = StorefrontPage(
                storefrontID: page.storefrontID,
                tabs: page.tabs,
                selectedTabID: page.selectedTabID,
                sections: combinedSections,
                nextPage: page.nextPage,
                loadedCount: page.loadedCount,
                totalCount: page.totalCount
            )

            tabCache[page.selectedTabID] = mergedPage
            selectedTabID = page.selectedTabID
            sections = combinedSections
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deduplicatedSections(_ input: [StorefrontSection]) -> [StorefrontSection] {
        var seen = Set<String>()
        return input.filter { seen.insert($0.id).inserted }
    }
}

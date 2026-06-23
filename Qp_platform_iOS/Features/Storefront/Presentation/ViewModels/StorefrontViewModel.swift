import Combine
import Foundation

@MainActor
final class StorefrontViewModel: ObservableObject {
    @Published private(set) var tabs: [StorefrontTab] = []
    @Published private(set) var selectedTabID: String?
    @Published private(set) var sections: [StorefrontSection] = []
    @Published private(set) var activeCohort: QuickplayCohort = .entertainment
    @Published private(set) var isInitialLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?

    private let initialUseCase: GetInitialStorefrontUseCase
    private let pageUseCase: GetStorefrontPageUseCase
    private let initialStorefrontID: String?
    private let preferredInitialTabTitle: String?
    private let fixedCohort: QuickplayCohort?
    private var storefrontID: String?
    private var tabCache: [String: StorefrontPage] = [:]
    private var activeProfileID: UUID?

    init(
        initialUseCase: GetInitialStorefrontUseCase,
        pageUseCase: GetStorefrontPageUseCase,
        initialStorefrontID: String? = nil,
        preferredInitialTabTitle: String? = nil,
        fixedCohort: QuickplayCohort? = nil
    ) {
        self.initialUseCase = initialUseCase
        self.pageUseCase = pageUseCase
        self.initialStorefrontID = initialStorefrontID
        self.preferredInitialTabTitle = preferredInitialTabTitle
        self.fixedCohort = fixedCohort
    }

    var selectedTabTitle: String {
        tabs.first(where: { $0.id == selectedTabID })?.title ?? AppStrings.Common.home
    }

    var demoHeroVariant: StorefrontHeroVariant {
        let normalizedTitle = selectedTabTitle.lowercased()

        if activeCohort == .sports || normalizedTitle.contains("sport") {
            return .stackedSports
        }

        if activeCohort == .realityShows ||
            normalizedTitle.contains("reality") ||
            normalizedTitle.contains("show")
        {
            return .immersive
        }

        return .carousel
    }

    var searchSeedItems: [StorefrontItem] {
        let sourceSections = sections.isEmpty ? tabCache.values.flatMap(\.sections) : sections
        var seen = Set<String>()
        return sourceSections.flatMap(\.items).filter { seen.insert($0.id).inserted }
    }

    func loadInitialIfNeeded() async {
        guard tabs.isEmpty, !isInitialLoading else { return }
        await load(storefrontID: initialStorefrontID, tabID: nil, pageNumber: 1, append: false, preserveVisibleContent: false)
    }

    func applyProfile(_ profile: Profile?) {
        let nextProfileID = profile?.id
        guard nextProfileID != activeProfileID else { return }
        activeProfileID = nextProfileID
        activeCohort = fixedCohort ?? profile?.quickplayCohort ?? .entertainment
        tabs = []
        selectedTabID = nil
        sections = []
        storefrontID = initialStorefrontID
        tabCache = [:]
        errorMessage = nil
    }

    func selectTab(_ tab: StorefrontTab) async {
        guard selectedTabID != tab.id || sections.isEmpty else { return }

        if let cached = tabCache[tab.id] {
            selectedTabID = cached.selectedTabID
            sections = cached.sections
            errorMessage = nil
            await load(storefrontID: storefrontID, tabID: tab.id, pageNumber: 1, append: false, preserveVisibleContent: true)
            return
        }

        await load(storefrontID: storefrontID, tabID: tab.id, pageNumber: 1, append: false, preserveVisibleContent: false)
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
        await load(storefrontID: storefrontID, tabID: tabID, pageNumber: pageNumber, append: append, preserveVisibleContent: false)
    }

    private func load(
        storefrontID: String?,
        tabID: String?,
        pageNumber: Int,
        append: Bool,
        preserveVisibleContent: Bool
    ) async {
        if let fixedCohort {
            activeCohort = fixedCohort
        } else {
            activeCohort = await DemoSessionStore.shared.currentCohort()
        }

        if append {
            isLoadingMore = true
        } else if preserveVisibleContent, !sections.isEmpty {
            isRefreshing = true
        } else {
            isInitialLoading = true
        }

        defer {
            isInitialLoading = false
            isLoadingMore = false
            isRefreshing = false
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

            if
                !append,
                tabID == nil,
                let preferredInitialTabTitle,
                let preferredTab = tabs.first(where: { $0.title.caseInsensitiveCompare(preferredInitialTabTitle) == .orderedSame }),
                preferredTab.id != page.selectedTabID
            {
                await selectTab(preferredTab)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deduplicatedSections(_ input: [StorefrontSection]) -> [StorefrontSection] {
        var seen = Set<String>()
        return input.filter { seen.insert($0.id).inserted }
    }
}

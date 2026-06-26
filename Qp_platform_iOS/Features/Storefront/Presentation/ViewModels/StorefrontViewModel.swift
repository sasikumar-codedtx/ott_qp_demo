import Combine
import Foundation
import UIKit

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
    @Published private(set) var scrollToTopToken = UUID()
    @Published private(set) var favoriteIDs: Set<String> = []

    private let initialUseCase: GetInitialStorefrontUseCase
    private let pageUseCase: GetStorefrontPageUseCase
    private let preferredInitialTabTitle: String?
    private let fixedCohort: QuickplayCohort?
    private var storefrontID: String?
    private var tabCache: [String: StorefrontPage] = [:]
    private var activeProfileID: UUID?

    init(
        initialUseCase: GetInitialStorefrontUseCase,
        pageUseCase: GetStorefrontPageUseCase,
        preferredInitialTabTitle: String? = nil,
        fixedCohort: QuickplayCohort? = nil
    ) {
        self.initialUseCase = initialUseCase
        self.pageUseCase = pageUseCase
        self.preferredInitialTabTitle = preferredInitialTabTitle
        self.fixedCohort = fixedCohort
    }

    var selectedTabTitle: String {
        tabs.first(where: { $0.id == selectedTabID })?.title ?? AppStrings.Common.home
    }

    var demoHeroVariant: StorefrontHeroVariant {
        let normalizedTitle = selectedTabTitle.lowercased()

        if normalizedTitle.contains("sport") {
            return .stackedSports
        }

        if normalizedTitle.contains("enter") {
            return .immersive
        }

        return .carousel
    }

    var heroPresentationCohort: QuickplayCohort {
        let normalizedTitle = selectedTabTitle.lowercased()

        if normalizedTitle.contains("sport") {
            return .sports
        }

        if normalizedTitle.contains("enter") {
            return .entertainment
        }

        return activeCohort
    }

    var searchSeedItems: [StorefrontItem] {
        let sourceSections = sections.isEmpty ? tabCache.values.flatMap(\.sections) : sections
        var seen = Set<String>()
        return sourceSections.flatMap(\.items).filter { seen.insert($0.id).inserted }
    }

    func loadInitialIfNeeded() async {
        guard tabs.isEmpty, !isInitialLoading else { return }
        await load(storefrontID: storefrontID, tabID: nil, pageNumber: 1, append: false, preserveVisibleContent: false)
    }

    func reloadInitial(force: Bool = false) async {
        guard force || !isInitialLoading else { return }
        if force {
            storefrontID = nil
        }
        await load(storefrontID: storefrontID, tabID: nil, pageNumber: 1, append: false, preserveVisibleContent: false)
    }

    func applyProfile(_ profile: Profile?, forceReset: Bool = false) {
        let nextProfileID = profile?.id
        guard forceReset || nextProfileID != activeProfileID else { return }
        activeProfileID = nextProfileID
        activeCohort = fixedCohort ?? profile?.quickplayCohort ?? .entertainment
        tabs = []
        selectedTabID = nil
        sections = []
        scrollToTopToken = UUID()
        isInitialLoading = true
        isRefreshing = false
        isLoadingMore = false
        storefrontID = nil
        tabCache = [:]
        errorMessage = nil
        Task {
            await refreshFavorites()
        }
    }

    func refreshFavorites() async {
        favoriteIDs = await DemoSessionStore.shared.favoriteIDs()
    }

    func toggleFavorite(_ item: StorefrontItem) async {
        let isFavorite = await DemoSessionStore.shared.toggleFavorite(item)
        if isFavorite {
            favoriteIDs.insert(item.id)
        } else {
            favoriteIDs.remove(item.id)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func selectTab(_ tab: StorefrontTab) async {
        guard selectedTabID != tab.id || sections.isEmpty else { return }
        scrollToTopToken = UUID()

        if let cached = tabCache[tab.id] {
            selectedTabID = cached.selectedTabID
            sections = cached.sections
            errorMessage = nil
            await load(storefrontID: storefrontID, tabID: tab.id, pageNumber: 1, append: false, preserveVisibleContent: false)
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

            if
                !append,
                tabID == nil,
                let preferredInitialTabTitle,
                let preferredTab = tabs.first(where: { $0.title.caseInsensitiveCompare(preferredInitialTabTitle) == .orderedSame }),
                preferredTab.id != page.selectedTabID
            {
                tabCache[page.selectedTabID] = page
                selectedTabID = preferredTab.id
                sections = []
                errorMessage = nil
                await load(storefrontID: page.storefrontID, tabID: preferredTab.id, pageNumber: 1, append: false, preserveVisibleContent: false)
                return
            }

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
                totalCount: page.totalCount,
                hasMore: page.hasMore
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

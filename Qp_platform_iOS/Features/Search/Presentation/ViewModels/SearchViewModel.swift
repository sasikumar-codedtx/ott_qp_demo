import Combine
import Foundation

struct SearchFilter: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedFilterID: String = SearchViewModel.allFilter.id
    @Published private(set) var results: [StorefrontItem] = []
    @Published private(set) var momentResults: [StorefrontItem] = []
    @Published private(set) var facetFilters: [SearchFilter] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let useCase: SearchContentUseCase
    private var cancellables = Set<AnyCancellable>()
    private var pendingManualDisplayQuery: String?
    private var currentSearchTerm = ""

    static let allFilter = SearchFilter(id: "all", title: "All")
    private static let defaultSearchQuery = "Trending Search"

    init(useCase: SearchContentUseCase) {
        self.useCase = useCase

        // .dropFirst() prevents the initial "" value from firing on app start.
        // Only fires when the user explicitly clears the field after entering the screen.
        $query
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .filter { $0.isEmpty }
            .sink { [weak self] _ in
                guard let self else { return }
                self.clearResults()
                self.isLoading = true
                Task { @MainActor [weak self] in
                    await self?.loadInitialContent()
                }
            }
            .store(in: &cancellables)
    }

    func submitSearch() {
        let term = normalizedQuery
        guard !term.isEmpty else { return }
        Task { @MainActor in
            await handleQueryChange(term)
        }
    }

    private func clearResults() {
        results = []
        momentResults = []
        facetFilters = []
        selectedFilterID = Self.allFilter.id
        errorMessage = nil
        isLoading = false
        currentSearchTerm = ""
    }

    private func loadInitialContent() async {
        // displayQuery: "" matches normalizedQuery "" so results are applied.
        // term: "Recent Movies" is what the API receives.
        await performSearch(term: "Recent Movies", facetTerm: nil, shouldUpdateFilters: false, displayQuery: "")
    }

    var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var availableFilters: [SearchFilter] {
        [Self.allFilter] + facetFilters
    }

    var displayedResults: [StorefrontItem] {
        results
    }

    var displaySearchTerm: String {
        normalizedQuery.isEmpty ? currentSearchTerm : normalizedQuery
    }

    let popularSuggestions: [String] = [
        "Trending Shows",
        "Action Movies",
        "Cricket Live",
        "South Films",
        "Thriller Series",
        "Comedy Movies",
        "Horror Shows",
        "Reality TV"
    ]

    func present() {
        clearResults()
        isLoading = true   // show spinner immediately before the async task starts
        pendingManualDisplayQuery = nil
        query = ""
        Task { @MainActor in
            await loadInitialContent()
        }
    }

    func submitAIQuery(_ query: String) {
        submitAIQuery(displayText: query, apiQuery: query)
    }

    func submitAIQuery(displayText: String, apiQuery: String) {
        let displayText = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        let queryToSearch = apiQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !displayText.isEmpty, !queryToSearch.isEmpty else { return }

        pendingManualDisplayQuery = displayText
        self.query = displayText
        selectedFilterID = Self.allFilter.id

        Task { @MainActor in
            await performSearch(
                term: queryToSearch,
                facetTerm: nil,
                shouldUpdateFilters: true,
                displayQuery: displayText
            )
        }
    }

    func selectFilter(_ filter: SearchFilter) {
        selectedFilterID = filter.id
        Task { @MainActor in
            await reloadForSelectedFacet()
        }
    }

    private func handleQueryChange(_ term: String) async {
        if pendingManualDisplayQuery == term {
            pendingManualDisplayQuery = nil
            return
        }

        guard !term.isEmpty else {
            errorMessage = nil
            isLoading = false
            selectedFilterID = Self.allFilter.id
            currentSearchTerm = ""
            return
        }

        selectedFilterID = Self.allFilter.id
        await performSearch(term: term, facetTerm: nil, shouldUpdateFilters: true, displayQuery: term)
    }

    private func reloadForSelectedFacet() async {
        let term = currentSearchTerm.isEmpty ? normalizedQuery : currentSearchTerm
        guard !term.isEmpty else { return }

        let facetTerm = selectedFilterID == Self.allFilter.id ? nil : selectedFilterID
        await performSearch(
            term: term,
            facetTerm: facetTerm,
            shouldUpdateFilters: facetTerm == nil,
            displayQuery: normalizedQuery
        )
    }

    private func performSearch(
        term: String,
        facetTerm: String?,
        shouldUpdateFilters: Bool,
        displayQuery: String
    ) async {
        isLoading = true
        errorMessage = nil
        results = []
        momentResults = []
        if shouldUpdateFilters {
            facetFilters = []
            selectedFilterID = Self.allFilter.id
        }
        currentSearchTerm = term

        do {
            let page = try await useCase.execute(term: term, facetTerm: facetTerm)
            if normalizedQuery.caseInsensitiveCompare(displayQuery) == .orderedSame {
                results = page.items
                momentResults = page.momentItems
                if page.items.isEmpty && page.momentItems.isEmpty {
                    facetFilters = []
                } else if shouldUpdateFilters {
                    facetFilters = deduplicatedFilters(page.filters)
                }
                isLoading = false
            }
        } catch {
            if normalizedQuery.caseInsensitiveCompare(displayQuery) == .orderedSame {
                facetFilters = []
                if error.localizedDescription.localizedCaseInsensitiveContains("no data match") {
                    results = []
                    momentResults = []
                    errorMessage = nil
                } else {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }

    private func deduplicatedFilters(_ filters: [SearchFilter]) -> [SearchFilter] {
        var seen = Set<String>()
        return filters.filter { filter in
            guard filter.id != Self.allFilter.id else { return false }
            return seen.insert(filter.id).inserted
        }
    }

}

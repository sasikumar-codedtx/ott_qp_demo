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
    @Published private(set) var facetFilters: [SearchFilter] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let useCase: SearchContentUseCase
    private var cancellables = Set<AnyCancellable>()

    static let allFilter = SearchFilter(id: "all", title: "All")
    private static let defaultSearchQuery = "Trending Search"

    init(useCase: SearchContentUseCase) {
        self.useCase = useCase

        $query
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] term in
                Task { @MainActor in
                    await self?.handleQueryChange(term)
                }
            }
            .store(in: &cancellables)

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

    func present() {
        results = []
        facetFilters = []
        selectedFilterID = Self.allFilter.id
        errorMessage = nil
        if query == Self.defaultSearchQuery {
            Task { @MainActor in
                await handleQueryChange(Self.defaultSearchQuery)
            }
        } else {
            query = Self.defaultSearchQuery
        }
    }

    func submitAIQuery(_ query: String) {
        let queryToSearch = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !queryToSearch.isEmpty else { return }
        self.query = queryToSearch
        selectedFilterID = Self.allFilter.id
    }

    func selectFilter(_ filter: SearchFilter) {
        selectedFilterID = filter.id
        Task { @MainActor in
            await reloadForSelectedFacet()
        }
    }

    private func handleQueryChange(_ term: String) async {
        guard !term.isEmpty else {
            errorMessage = nil
            isLoading = false
            selectedFilterID = Self.allFilter.id
            return
        }

        selectedFilterID = Self.allFilter.id
        await performSearch(term: term, facetTerm: nil, shouldUpdateFilters: true)
    }

    private func reloadForSelectedFacet() async {
        let term = normalizedQuery
        guard !term.isEmpty else { return }

        let facetTerm = selectedFilterID == Self.allFilter.id ? nil : selectedFilterID
        await performSearch(term: term, facetTerm: facetTerm, shouldUpdateFilters: facetTerm == nil)
    }

    private func performSearch(term: String, facetTerm: String?, shouldUpdateFilters: Bool) async {
        isLoading = true
        errorMessage = nil
        results = []

        do {
            let page = try await useCase.execute(term: term, facetTerm: facetTerm)
            if normalizedQuery.caseInsensitiveCompare(term) == .orderedSame {
                results = page.items
                if shouldUpdateFilters {
                    facetFilters = deduplicatedFilters(page.filters)
                }
                isLoading = false
            }
        } catch {
            if normalizedQuery.caseInsensitiveCompare(term) == .orderedSame {
                if error.localizedDescription.localizedCaseInsensitiveContains("no data match") {
                    results = []
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

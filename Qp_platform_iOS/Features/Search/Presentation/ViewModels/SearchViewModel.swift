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
    @Published private(set) var popularItems: [StorefrontItem] = []
    @Published private(set) var results: [StorefrontItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let useCase: SearchContentUseCase
    private var cache: [String: [StorefrontItem]] = [:]
    private var cancellables = Set<AnyCancellable>()

    static let allFilter = SearchFilter(id: "all", title: "All")

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
        let classifications = results
            .map(\.derivedSearchFilter)
            .reduce(into: [String: SearchFilter]()) { partialResult, filter in
                partialResult[filter.id] = filter
            }

        let sortedFilters = classifications.values.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        return [Self.allFilter] + sortedFilters
    }

    var displayedResults: [StorefrontItem] {
        let filtered = results.filter { item in
            selectedFilterID == Self.allFilter.id || item.derivedSearchFilter.id == selectedFilterID
        }

        return filtered.isEmpty ? results : filtered
    }

    func present(popularItems: [StorefrontItem]) {
        self.popularItems = Array(popularItems.prefix(15))
        query = ""
        results = []
        selectedFilterID = Self.allFilter.id
        errorMessage = nil
    }

    private func handleQueryChange(_ term: String) async {
        guard !term.isEmpty else {
            results = []
            errorMessage = nil
            isLoading = false
            selectedFilterID = Self.allFilter.id
            return
        }

        if let cached = cache[term.lowercased()] {
            results = cached
            errorMessage = nil
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        selectedFilterID = Self.allFilter.id

        do {
            let items = try await useCase.execute(term: term)
            cache[term.lowercased()] = items
            if normalizedQuery.caseInsensitiveCompare(term) == .orderedSame {
                results = items
                synchronizeSelectedFilter()
                isLoading = false
            }
        } catch {
            if normalizedQuery.caseInsensitiveCompare(term) == .orderedSame {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func synchronizeSelectedFilter() {
        if availableFilters.contains(where: { $0.id == selectedFilterID }) == false {
            selectedFilterID = Self.allFilter.id
        }
    }
}

extension StorefrontItem {
    var derivedSearchFilter: SearchFilter {
        let type = contentType.lowercased()
        let searchableGenres = genres.map { $0.lowercased() }

        if type.contains("highlight") || type.contains("clip") || type.contains("short") {
            return SearchFilter(id: "clips", title: "Clips")
        }

        if type.contains("micro") || searchableGenres.contains(where: { $0.contains("micro") || $0.contains("drama") }) {
            return SearchFilter(id: "micro-drama", title: "Micro Drama")
        }

        if type.contains("series") || type.contains("show") || type.contains("episode") {
            return SearchFilter(id: "shows", title: "Shows")
        }

        if type.contains("movie") || searchableGenres.contains(where: { $0.contains("movie") || $0.contains("film") }) {
            return SearchFilter(id: "movies", title: "Movies")
        }

        return SearchFilter(id: type.nilIfEmpty ?? "content", title: contentType.capitalized)
    }
}

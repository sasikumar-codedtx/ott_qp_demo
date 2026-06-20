import Combine
import Foundation

enum SearchCategory: String, CaseIterable, Identifiable {
    case trending = "Trending"
    case clips = "Clips"
    case shows = "Shows"
    case action = "Action"
    case sports = "Sports"

    var id: String { rawValue }
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedCategory: SearchCategory = .trending
    @Published private(set) var popularItems: [StorefrontItem] = []
    @Published private(set) var results: [StorefrontItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let useCase: SearchContentUseCase
    private var cache: [String: [StorefrontItem]] = [:]
    private var cancellables = Set<AnyCancellable>()

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

    var displayedResults: [StorefrontItem] {
        let filtered = results.filter { item in
            switch selectedCategory {
            case .trending:
                return true
            case .clips:
                return item.contentType.contains("trailer") || item.contentType.contains("clip")
            case .shows:
                return item.contentType.contains("webseries") || item.contentType.contains("webepisode") || item.contentType.contains("show")
            case .action:
                return item.genres.contains(where: { $0.localizedCaseInsensitiveContains("action") })
            case .sports:
                return item.genres.contains(where: { $0.localizedCaseInsensitiveContains("sport") }) || item.title.localizedCaseInsensitiveContains("sport")
            }
        }

        return filtered.isEmpty ? results : filtered
    }

    func present(popularItems: [StorefrontItem]) {
        self.popularItems = Array(popularItems.prefix(15))
        query = ""
        results = []
        selectedCategory = .trending
        errorMessage = nil
    }

    private func handleQueryChange(_ term: String) async {
        guard !term.isEmpty else {
            results = []
            errorMessage = nil
            isLoading = false
            selectedCategory = .trending
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
        selectedCategory = .trending

        do {
            let items = try await useCase.execute(term: term)
            cache[term.lowercased()] = items
            if normalizedQuery.caseInsensitiveCompare(term) == .orderedSame {
                results = items
                isLoading = false
            }
        } catch {
            if normalizedQuery.caseInsensitiveCompare(term) == .orderedSame {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

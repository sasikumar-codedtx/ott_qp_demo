import Combine
import Foundation

@MainActor
final class ContentDetailViewModel: ObservableObject {
    @Published private(set) var seed: StorefrontItem?
    @Published private(set) var detail: ContentDetail?
    @Published private(set) var recommendations: [StorefrontItem] = []
    @Published private(set) var momentResults: [StorefrontItem] = []
    @Published private(set) var isLoadingMoments = false
    @Published private(set) var momentsErrorMessage: String?
    @Published private(set) var episodes: [StorefrontItem] = []
    @Published private(set) var isLoadingEpisodes = false
    @Published private(set) var episodesErrorMessage: String?
    @Published var momentQuery = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var selectedTab: String = AppStrings.Detail.moreLikeThis

    private let detailUseCase: GetContentDetailUseCase
    private let recommendationsUseCase: GetRecommendationsUseCase
    private let momentsUseCase: GetContentMomentsUseCase
    private let episodesUseCase: GetContentEpisodesUseCase
    private var loadedPath: String?
    private var lastMomentSearchTerm: String?
    private var loadedEpisodesSeriesID: String?

    init(
        detailUseCase: GetContentDetailUseCase,
        recommendationsUseCase: GetRecommendationsUseCase,
        momentsUseCase: GetContentMomentsUseCase,
        episodesUseCase: GetContentEpisodesUseCase
    ) {
        self.detailUseCase = detailUseCase
        self.recommendationsUseCase = recommendationsUseCase
        self.momentsUseCase = momentsUseCase
        self.episodesUseCase = episodesUseCase
    }

    var requestKey: String {
        seed?.detailID ?? seed?.id ?? "detail"
    }

    func present(item: StorefrontItem) {
        let nextPath = item.detailID ?? item.id
        let currentPath = seed?.detailID ?? seed?.id

        seed = item
        selectedTab = AppStrings.Detail.moreLikeThis

        guard nextPath != currentPath else { return }

        detail = nil
        recommendations = []
        resetMoments()
        resetEpisodes()
        errorMessage = nil
        loadedPath = nil
    }

    func loadIfNeeded() async {
        guard loadedPath != requestKey else { return }
        await load()
    }

    func load() async {
        guard let seed, let detailID = seed.detailID else {
            errorMessage = "This title is not available for detail navigation yet."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            async let detailResponse = detailUseCase.execute(itemID: detailID)
            async let recommendationResponse = recommendationsUseCase.execute(
                itemID: seed.id,
                contentType: seed.contentType,
                fallbackQuery: seed.genres.first ?? seed.title
            )

            let (detail, recommendations) = try await (detailResponse, recommendationResponse)
            self.detail = detail
            self.recommendations = recommendations
            self.loadedPath = requestKey
            isLoading = false

            if detail.supportsEpisodes {
                await loadEpisodes(for: detail, seedSeriesID: seed.seriesId)
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func selectTab(_ tab: String) {
        selectedTab = tab
    }

    func submitMomentSearch(_ term: String) {
        momentQuery = term.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await searchMoments(term: momentQuery, allowDefault: false, force: true)
        }
    }

    func momentSuggestions(for detail: ContentDetail) -> [String] {
        let title = detail.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let genres = detail.genres.prefix(2)
        var suggestions = [
            "\(title) best scenes",
            "\(title) key moments",
            "emotional scene"
        ]

        suggestions.append(contentsOf: genres.map { "\($0) moments" })
        return Array(suggestions.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }.prefix(5))
    }

    private func resetMoments() {
        momentQuery = ""
        momentResults = []
        isLoadingMoments = false
        momentsErrorMessage = nil
        lastMomentSearchTerm = nil
    }

    private func resetEpisodes() {
        episodes = []
        isLoadingEpisodes = false
        episodesErrorMessage = nil
        loadedEpisodesSeriesID = nil
    }

    private func loadEpisodes(for detail: ContentDetail, seedSeriesID: String? = nil, force: Bool = false) async {
        let seriesID = seedSeriesID?.nilIfEmpty ?? detail.episodeSeriesId
        guard force || loadedEpisodesSeriesID != seriesID else { return }

        loadedEpisodesSeriesID = seriesID
        isLoadingEpisodes = true
        episodesErrorMessage = nil

        do {
            episodes = try await episodesUseCase.execute(seriesID: seriesID)
            isLoadingEpisodes = false
        } catch {
            episodes = []
            episodesErrorMessage = error.localizedDescription
            isLoadingEpisodes = false
        }
    }

    private func searchMoments(term: String, allowDefault: Bool, force: Bool = false) async {
        guard let detail else { return }
        let normalizedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchTerm = normalizedTerm.isEmpty && allowDefault ? detail.title : normalizedTerm

        guard searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            momentResults = []
            momentsErrorMessage = nil
            return
        }

        guard force || lastMomentSearchTerm != searchTerm else { return }

        lastMomentSearchTerm = searchTerm
        isLoadingMoments = true
        momentsErrorMessage = nil

        do {
            momentResults = try await momentsUseCase.execute(contentID: detail.id, term: searchTerm)
            isLoadingMoments = false
        } catch {
            momentResults = []
            momentsErrorMessage = error.localizedDescription
            isLoadingMoments = false
        }
    }
}

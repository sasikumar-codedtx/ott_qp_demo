import Combine
import Foundation

@MainActor
final class ContentDetailViewModel: ObservableObject {
    @Published private(set) var seed: StorefrontItem?
    @Published private(set) var detail: ContentDetail?
    @Published private(set) var recommendations: [StorefrontItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var selectedTab: String = AppStrings.Detail.moreLikeThis

    private let detailUseCase: GetContentDetailUseCase
    private let recommendationsUseCase: GetRecommendationsUseCase
    private var loadedPath: String?

    init(detailUseCase: GetContentDetailUseCase, recommendationsUseCase: GetRecommendationsUseCase) {
        self.detailUseCase = detailUseCase
        self.recommendationsUseCase = recommendationsUseCase
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
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

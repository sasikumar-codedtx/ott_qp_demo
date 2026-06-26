import Combine
import Foundation

@MainActor
final class ProfileHubViewModel: ObservableObject {
    @Published private(set) var selectedProfile: Profile?
    @Published private(set) var heroItem: StorefrontItem?
    @Published private(set) var sections: [StorefrontSection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let useCase: GetProfileHomeUseCase
    private var clipSeedItems: [StorefrontItem] = []
    private var hasLoaded = false

    init(useCase: GetProfileHomeUseCase) {
        self.useCase = useCase
    }

    var displayedProfileName: String {
        selectedProfile?.name ?? "Default"
    }

    var displayedProfileImageName: String? {
        selectedProfile?.imageName ?? ProfileArtworkResolver.randomizedImageName(forName: displayedProfileName)
    }

    var leadingSection: StorefrontSection? {
        sections.first { $0.id == "continue-watching" }
    }

    var trailingSections: [StorefrontSection] {
        sections.filter { $0.id != "continue-watching" }
    }

    func present(profile: Profile?, seedItems: [StorefrontItem]) {
        selectedProfile = profile
        clipSeedItems = seedItems
        heroItem = seedItems.first
        sections = []
        errorMessage = nil
        hasLoaded = false
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await load()
    }

    private func load() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let home = try await useCase.execute(profile: selectedProfile, seedItems: clipSeedItems)
            let clipItems = buildClipItems(from: clipSeedItems, fallbacks: home.recommendations + home.favorites)

            sections = [
                makeSection(id: "continue-watching", title: AppStrings.Profile.continueWatching, ratio: "0-2x3", items: home.continueWatching),
                makeSection(id: "clips", title: AppStrings.Profile.clips, ratio: "0-9x16", items: clipItems),
                makeSection(id: "liked", title: AppStrings.Profile.liked, ratio: "0-2x3", items: home.recommendations),
                makeSection(id: "favorites", title: AppStrings.Profile.favorites, ratio: "0-2x3", items: home.favorites)
            ]
            .compactMap { $0 }

            heroItem = home.continueWatching.first ?? clipItems.first ?? home.favorites.first ?? home.recommendations.first
        } catch {
            errorMessage = error.localizedDescription
            sections = []
        }
    }

    private func makeSection(id: String, title: String, ratio: String, items: [StorefrontItem]) -> StorefrontSection? {
        let deduplicated = deduplicatedItems(items)
        guard !deduplicated.isEmpty else { return nil }
        return StorefrontSection(id: id, title: title, ratio: ratio, items: deduplicated, isHero: false)
    }

    private func buildClipItems(from seeds: [StorefrontItem], fallbacks: [StorefrontItem]) -> [StorefrontItem] {
        let candidates = deduplicatedItems(seeds + fallbacks)
        let portraitFirst = candidates.filter { $0.availableRatios.contains("0-9x16") || $0.availableRatios.contains("0-2x3") }
        return Array((portraitFirst.isEmpty ? candidates : portraitFirst).prefix(6))
    }

    private func deduplicatedItems(_ items: [StorefrontItem]) -> [StorefrontItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }
}

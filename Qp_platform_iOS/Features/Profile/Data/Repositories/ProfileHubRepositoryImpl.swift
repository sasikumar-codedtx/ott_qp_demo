import Foundation

final class ProfileHubRepositoryImpl: ProfileHubRepository {
    func fetchHome(profile: Profile?, seedItems: [StorefrontItem]) async throws -> ProfileHomeData {
        let continueWatchingItems = await DemoSessionStore.shared.continueWatchingItems(for: profile?.id, limit: 10)
        let persistedFavorites = await DemoSessionStore.shared.favoriteItems(limit: 10)
        let persistedLikes = await DemoSessionStore.shared.likedItems(limit: 20)
        let sourceItems: [StorefrontItem]
        if profile?.isKidsProfile == true {
            sourceItems = seedItems.filter { $0.availableRatios.contains("0-1x1") || $0.availableRatios.contains("0-2x3") }
        } else {
            sourceItems = seedItems
        }

        return ProfileHomeData(
            continueWatching: DemoRailComposer.continueWatching(from: continueWatchingItems),
            likedItems: persistedLikes,
            favorites: persistedFavorites.isEmpty ? buildFavoritesMock(from: sourceItems) : persistedFavorites,
            recommendations: DemoRailComposer.recommendations(from: sourceItems)
        )
    }

    private func buildFavoritesMock(from items: [StorefrontItem]) -> [StorefrontItem] {
        let posters = items.filter { $0.availableRatios.contains("0-2x3") || $0.availableRatios.contains("0-1x1") }
        let prioritized = posters.isEmpty ? items : posters
        let rotated = Array(prioritized.dropFirst(1)) + Array(prioritized.prefix(1))
        return DemoRailComposer.favorites(from: rotated, limit: 10)
    }
}

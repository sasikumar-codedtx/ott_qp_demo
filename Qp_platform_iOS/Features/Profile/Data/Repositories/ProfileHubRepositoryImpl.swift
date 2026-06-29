import Foundation

final class ProfileHubRepositoryImpl: ProfileHubRepository {
    func fetchHome(profile: Profile?, seedItems: [StorefrontItem]) async throws -> ProfileHomeData {
        let continueWatchingItems = await DemoSessionStore.shared.continueWatchingItems(for: profile?.id, limit: 10)
        let persistedFavorites = await DemoSessionStore.shared.favoriteItems(for: profile?.id, limit: 10)
        let persistedLikes = await DemoSessionStore.shared.likedItems(for: profile?.id, limit: 20)

        return ProfileHomeData(
            continueWatching: DemoRailComposer.continueWatching(from: continueWatchingItems),
            likedItems: persistedLikes,
            favorites: persistedFavorites,
            clips: DemoRailComposer.recommendations(from: seedItems)
        )
    }
}

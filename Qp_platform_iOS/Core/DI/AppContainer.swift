import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let authRepository: AuthRepository
    let profileRepository: ProfileRepository
    let profileHubRepository: ProfileHubRepository
    let storefrontRepository: StorefrontRepository
    let searchRepository: SearchRepository
    let shortsRepository: ShortsRepository
    let contentDetailRepository: ContentDetailRepository

    private let profileDataSource: ProfileMockDataSource

    private init() {
        let networkClient = NetworkClient()

        let authDataSource = AuthMockDataSource()
        authRepository = AuthRepositoryImpl(dataSource: authDataSource)

        profileDataSource = ProfileMockDataSource()
        profileRepository = ProfileRepositoryImpl(dataSource: profileDataSource)

        profileHubRepository = ProfileHubRepositoryImpl()

        let storefrontRemoteDataSource = StorefrontRemoteDataSource(
            apiClient: StorefrontAPIClient(networkClient: networkClient)
        )
        storefrontRepository = StorefrontRepositoryImpl(dataSource: storefrontRemoteDataSource)

        let searchRemoteDataSource = SearchRemoteDataSource(
            apiClient: SearchAPIClient(networkClient: networkClient)
        )
        searchRepository = SearchRepositoryImpl(dataSource: searchRemoteDataSource)

        shortsRepository = MockShortsRepository()

        let detailRemoteDataSource = ContentDetailRemoteDataSource(
            apiClient: ContentDetailAPIClient(networkClient: networkClient)
        )
        contentDetailRepository = ContentDetailRepositoryImpl(dataSource: detailRemoteDataSource)
    }

    func switchAccount(phoneNumber: String) {
        UserDefaults.standard.set(phoneNumber, forKey: "sony.quickplay.demo.active-phone-number")
        profileDataSource.reloadForCurrentPhone()
    }

    /// Reloads profiles from the phone number already stored in UserDefaults.
    /// Call after app launch when the user is already logged in.
    func reloadProfilesForStoredPhone() {
        profileDataSource.reloadForCurrentPhone()
    }

    /// Clears in-memory profiles on sign-out so stale data isn't visible before re-login.
    func clearInMemoryProfiles() {
        profileDataSource.clearInMemoryProfiles()
    }
}

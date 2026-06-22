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

    private init() {
        let networkClient = NetworkClient()

        let authDataSource = AuthMockDataSource()
        authRepository = AuthRepositoryImpl(dataSource: authDataSource)

        let profileDataSource = ProfileMockDataSource()
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
}

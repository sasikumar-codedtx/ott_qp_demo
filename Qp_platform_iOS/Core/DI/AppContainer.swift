import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let authRepository: AuthRepository
    let profileRepository: ProfileRepository
    let profileHubRepository: ProfileHubRepository
    let storefrontRepository: StorefrontRepository
    let searchRepository: SearchRepository
    let contentDetailRepository: ContentDetailRepository

    private init() {
        let networkClient = NetworkClient()

        let authDataSource = AuthMockDataSource()
        authRepository = AuthRepositoryImpl(dataSource: authDataSource)

        let profileDataSource = ProfileMockDataSource()
        profileRepository = ProfileRepositoryImpl(dataSource: profileDataSource)

        let profileHubRemoteDataSource = ProfileHubRemoteDataSource(
            apiClient: ProfileHubAPIClient(networkClient: networkClient)
        )
        profileHubRepository = ProfileHubRepositoryImpl(dataSource: profileHubRemoteDataSource)

        let storefrontRemoteDataSource = StorefrontRemoteDataSource(
            apiClient: StorefrontAPIClient(networkClient: networkClient)
        )
        storefrontRepository = StorefrontRepositoryImpl(dataSource: storefrontRemoteDataSource)

        let searchRemoteDataSource = SearchRemoteDataSource(
            apiClient: SearchAPIClient(networkClient: networkClient)
        )
        searchRepository = SearchRepositoryImpl(dataSource: searchRemoteDataSource)

        let detailRemoteDataSource = ContentDetailRemoteDataSource(
            apiClient: ContentDetailAPIClient(networkClient: networkClient)
        )
        contentDetailRepository = ContentDetailRepositoryImpl(dataSource: detailRemoteDataSource)
    }
}

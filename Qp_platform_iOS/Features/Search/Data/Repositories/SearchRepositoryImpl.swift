import Foundation

final class SearchRepositoryImpl: SearchRepository {
    private let dataSource: SearchDataSourceProtocol
    private let configStore: QuickplayConfigurationStore

    init(dataSource: SearchDataSourceProtocol, configStore: QuickplayConfigurationStore = .shared) {
        self.dataSource = dataSource
        self.configStore = configStore
    }

    func search(term: String) async throws -> [StorefrontItem] {
        let response = try await dataSource.search(term: term)
        let config = await configStore.current()
        return response.data.map { $0.toDomain(config: config) }
    }
}

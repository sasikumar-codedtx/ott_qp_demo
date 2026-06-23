import Foundation

final class ContentDetailRepositoryImpl: ContentDetailRepository {
    private let dataSource: ContentDetailDataSourceProtocol
    private let configStore: QuickplayConfigurationStore

    init(dataSource: ContentDetailDataSourceProtocol, configStore: QuickplayConfigurationStore = .shared) {
        self.dataSource = dataSource
        self.configStore = configStore
    }

    func fetchDetail(itemID: String) async throws -> ContentDetail {
        guard let item = try await dataSource.fetchDetail(itemID: itemID).data.first else {
            throw AppError.invalidResponse
        }
        let config = await configStore.current()
        return item.toDetailDomain(config: config)
    }

    func fetchRecommendations(itemID: String, contentType: String, fallbackQuery: String) async throws -> [StorefrontItem] {
        let config = await configStore.current()
        do {
            let remoteItems = try await dataSource.fetchRecommendations(itemID: itemID, contentType: contentType).data.map { $0.toDomain(config: config) }
            let filteredRemoteItems = remoteItems.filter { $0.id != itemID }
            if filteredRemoteItems.isEmpty == false {
                return filteredRemoteItems
            }
        } catch {
            // Fall through to Sony search-backed fallback.
        }

        let searchTerm = fallbackQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard searchTerm.isEmpty == false else { return [] }

        let fallbackItems = try await dataSource.searchRecommendations(term: searchTerm).data
            .map { $0.toDomain(config: config) }
            .filter { $0.id != itemID }

        return Array(fallbackItems.prefix(18))
    }
}

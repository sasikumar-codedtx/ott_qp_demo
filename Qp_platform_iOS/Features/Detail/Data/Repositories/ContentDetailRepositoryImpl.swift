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

    func searchMoments(contentID: String, term: String) async throws -> [StorefrontItem] {
        let normalizedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedTerm.isEmpty == false else { return [] }

        let config = await configStore.current()
        return try await dataSource.searchMoments(contentID: contentID, term: normalizedTerm).data
            .map { $0.toDomain(config: config) }
            .filter { $0.id != contentID }
    }

    func fetchEpisodes(seriesID: String) async throws -> [StorefrontItem] {
        let normalizedSeriesID = seriesID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedSeriesID.isEmpty == false else { return [] }

        let config = await configStore.current()
        return try await dataSource.fetchEpisodes(seriesID: normalizedSeriesID).data
            .map { $0.toDomain(config: config) }
    }
}

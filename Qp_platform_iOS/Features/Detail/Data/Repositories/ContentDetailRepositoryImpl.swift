import Foundation

final class ContentDetailRepositoryImpl: ContentDetailRepository {
    private let dataSource: ContentDetailDataSourceProtocol
    private let configStore: QuickplayConfigurationStore
    private var seasonCacheBySeriesID: [String: [ContentSeason]] = [:]
    private var episodeCacheBySeriesSeasonID: [String: [StorefrontItem]] = [:]

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

    func fetchEpisodeBundle(seriesID: String) async throws -> ContentEpisodeBundle {
        let normalizedSeriesID = seriesID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedSeriesID.isEmpty == false else {
            return ContentEpisodeBundle(seasons: [], selectedSeason: nil, episodes: [])
        }

        let seasons = try await cachedSeasons(seriesID: normalizedSeriesID)
        guard let selectedSeason = seasons.first else {
            return ContentEpisodeBundle(seasons: [], selectedSeason: nil, episodes: [])
        }

        let episodes = try await fetchEpisodes(seriesID: normalizedSeriesID, seasonID: selectedSeason.id)
        return ContentEpisodeBundle(seasons: seasons, selectedSeason: selectedSeason, episodes: episodes)
    }

    func fetchEpisodes(seriesID: String, seasonID: String) async throws -> [StorefrontItem] {
        let normalizedSeriesID = seriesID.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSeasonID = seasonID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedSeriesID.isEmpty == false, normalizedSeasonID.isEmpty == false else { return [] }

        let cacheKey = "\(normalizedSeriesID)::\(normalizedSeasonID)"
        if let cachedEpisodes = episodeCacheBySeriesSeasonID[cacheKey] {
            return cachedEpisodes
        }

        let config = await configStore.current()
        let episodes = try await dataSource.fetchEpisodes(seriesID: normalizedSeriesID, seasonID: normalizedSeasonID).data
            .map { $0.toDomain(config: config) }
        episodeCacheBySeriesSeasonID[cacheKey] = episodes
        return episodes
    }

    private func cachedSeasons(seriesID: String) async throws -> [ContentSeason] {
        if let cachedSeasons = seasonCacheBySeriesID[seriesID] {
            return cachedSeasons
        }

        let seasons = try await dataSource.fetchSeasons(seriesID: seriesID).data.enumerated().compactMap { index, item in
            item.id.nilIfEmpty.map {
                ContentSeason(
                    id: $0,
                    title: item.lon?.preferredText.nilIfEmpty ?? "Season \(index + 1)"
                )
            }
        }
        seasonCacheBySeriesID[seriesID] = seasons
        return seasons
    }
}

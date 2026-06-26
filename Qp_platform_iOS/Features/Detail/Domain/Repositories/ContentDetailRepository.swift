import Foundation

protocol ContentDetailRepository {
    func fetchDetail(itemID: String) async throws -> ContentDetail
    func fetchRecommendations(itemID: String, contentType: String, fallbackQuery: String) async throws -> [StorefrontItem]
    func searchMoments(contentID: String, term: String) async throws -> [StorefrontItem]
    func fetchEpisodeBundle(seriesID: String) async throws -> ContentEpisodeBundle
    func fetchEpisodes(seriesID: String, seasonID: String) async throws -> [StorefrontItem]
}

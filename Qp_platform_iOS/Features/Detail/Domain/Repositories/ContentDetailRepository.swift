import Foundation

protocol ContentDetailRepository {
    func fetchDetail(itemID: String) async throws -> ContentDetail
    func fetchRecommendations(itemID: String, contentType: String, fallbackQuery: String) async throws -> [StorefrontItem]
}

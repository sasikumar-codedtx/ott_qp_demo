import Foundation

protocol ContentDetailRepository {
    func fetchDetail(path: String) async throws -> ContentDetail
    func fetchRecommendations(itemID: String, contentType: String) async throws -> [StorefrontItem]
}

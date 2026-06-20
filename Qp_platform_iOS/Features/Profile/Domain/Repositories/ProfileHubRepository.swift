import Foundation

protocol ProfileHubRepository {
    func fetchHome(profileRecommendationID: String) async throws -> ProfileHomeData
}

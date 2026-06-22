import Foundation

protocol ProfileHubRepository {
    func fetchHome(profile: Profile?, seedItems: [StorefrontItem]) async throws -> ProfileHomeData
}

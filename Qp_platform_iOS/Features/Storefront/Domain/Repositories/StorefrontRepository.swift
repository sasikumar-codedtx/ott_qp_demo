import Foundation

protocol StorefrontRepository {
    func fetchLanding(storefrontID: String?, tabID: String?, pageNumber: Int) async throws -> StorefrontPage
}

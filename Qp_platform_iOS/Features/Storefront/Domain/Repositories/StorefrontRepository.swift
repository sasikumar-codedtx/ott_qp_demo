import Foundation

protocol StorefrontRepository {
    func fetchLanding(storefrontID: String?, tabID: String?, pageNumber: Int) async throws -> StorefrontPage
    func fetchSectionPage(ids: [String], pageNumber: Int, pageSize: Int) async throws -> StorefrontSectionPage
    func fetchCollectionLookupPage(item: StorefrontItem, pageNumber: Int, pageSize: Int) async throws -> StorefrontSectionPage
}

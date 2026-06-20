import Foundation

protocol SearchRepository {
    func search(term: String) async throws -> [StorefrontItem]
}

import Foundation

protocol ShortsRepository {
    func fetchBatch(offset: Int, limit: Int) async throws -> ShortsBatch
}

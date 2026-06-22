import Foundation

struct GetShortsBatchUseCase {
    let repository: ShortsRepository

    func execute(offset: Int, limit: Int) async throws -> ShortsBatch {
        try await repository.fetchBatch(offset: offset, limit: limit)
    }
}

import Foundation

final class SearchRepositoryImpl: SearchRepository {
    private let dataSource: SearchDataSourceProtocol

    init(dataSource: SearchDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func search(term: String) async throws -> [StorefrontItem] {
        let response = try await dataSource.search(term: term)
        return response.data.map { $0.toDomain() }
    }
}

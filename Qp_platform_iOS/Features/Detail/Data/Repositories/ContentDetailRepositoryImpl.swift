import Foundation

final class ContentDetailRepositoryImpl: ContentDetailRepository {
    private let dataSource: ContentDetailDataSourceProtocol

    init(dataSource: ContentDetailDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func fetchDetail(path: String) async throws -> ContentDetail {
        try await dataSource.fetchDetail(path: path).data.toDomain()
    }

    func fetchRecommendations(itemID: String, contentType: String) async throws -> [StorefrontItem] {
        try await dataSource.fetchRecommendations(itemID: itemID, contentType: contentType).data.map { $0.toDomain() }
    }
}

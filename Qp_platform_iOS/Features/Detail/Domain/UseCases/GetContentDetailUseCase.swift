import Foundation

struct GetContentDetailUseCase {
    private let repository: ContentDetailRepository

    init(repository: ContentDetailRepository) {
        self.repository = repository
    }

    func execute(path: String) async throws -> ContentDetail {
        try await repository.fetchDetail(path: path)
    }
}

import Foundation

struct ContentDetailAPIClient {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    func fetchDetail(path: String) async throws -> ContentDetailResponseDTO {
        guard let request = ContentDetailRouter.detail(path: path).urlRequest else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            return try JSONDecoder().decode(ContentDetailResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }

    func fetchRecommendations(itemID: String, contentType: String) async throws -> RecommendationResponseDTO {
        guard let request = ContentDetailRouter.recommendations(itemID: itemID, contentType: contentType).urlRequest else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            return try JSONDecoder().decode(RecommendationResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }
}

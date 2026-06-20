import Foundation

struct SearchAPIClient {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    func search(term: String) async throws -> SearchResponseDTO {
        guard let request = SearchRouter.search(term: term).urlRequest else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            return try JSONDecoder().decode(SearchResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }
}

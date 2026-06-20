import Foundation

struct StorefrontAPIClient {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    func fetchLanding(storefrontID: String?, tabID: String?, pageNumber: Int) async throws -> StorefrontResponseDTO {
        guard let request = StorefrontRouter.landing(storefrontID: storefrontID, tabID: tabID, pageNumber: pageNumber).urlRequest else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            return try JSONDecoder().decode(StorefrontResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }
}

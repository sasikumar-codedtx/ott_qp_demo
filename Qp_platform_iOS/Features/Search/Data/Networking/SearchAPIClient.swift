import Foundation

struct SearchAPIClient {
    private let networkClient: NetworkClient
    private let configStore: QuickplayConfigurationStore

    init(
        networkClient: NetworkClient = NetworkClient(),
        configStore: QuickplayConfigurationStore = .shared
    ) {
        self.networkClient = networkClient
        self.configStore = configStore
    }

    func search(term: String) async throws -> SearchResponseDTO {
        let config = await configStore.current(using: networkClient)
        let cohort = await DemoSessionStore.shared.currentCohort()
        guard let request = SearchRouter.makeRequest(term: term, config: config, cohort: cohort) else {
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

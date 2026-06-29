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

    func search(term: String, facetTerm: String?, moment: Bool) async throws -> SearchResponseDTO {
        let config = await configStore.current(using: networkClient)
        let cohort = await DemoSessionStore.shared.currentCohort()
        let policyAttribute = await DemoSessionStore.shared.currentStorefrontPolicyAttribute()
        guard let request = SearchRouter.makeRequest(
            term: term,
            facetTerm: facetTerm,
            moment: moment,
            config: config,
            cohort: cohort,
            policyAttribute: policyAttribute
        ) else {
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

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

    func search(term: String, facetTerm: String?) async throws -> SearchResponseDTO {
        let config = await configStore.current(using: networkClient)
        let cohort = await DemoSessionStore.shared.currentCohort()
        guard let request = SearchRouter.makeRequest(term: term, facetTerm: facetTerm, config: config, cohort: cohort) else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            let response = try JSONDecoder().decode(SearchResponseDTO.self, from: data)
            SearchAPILogger.log(request: request, response: response)
            return response
        } catch {
            throw AppError.decodingFailed
        }
    }

}

private enum SearchAPILogger {
    static func log(request: URLRequest, response: SearchResponseDTO) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<missing-url>"
        let facetCount = response.facet?.terms?.count ?? 0

        print("""

        🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥 SEARCH API 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
        request:
        \(method) \(url)

        response:
        statusCode/message: \(response.header.code) / \(response.header.message)
        data count -> \(response.data.count)
        facet terms count -> \(facetCount)
        🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥 SEARCH API END 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥

        """)
    }
}

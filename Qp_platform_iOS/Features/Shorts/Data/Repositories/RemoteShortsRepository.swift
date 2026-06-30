import Foundation

struct RemoteShortsRepository: ShortsRepository {
    private let networkClient: NetworkClient
    private let configStore: QuickplayConfigurationStore

    init(
        networkClient: NetworkClient = NetworkClient(),
        configStore: QuickplayConfigurationStore = .shared
    ) {
        self.networkClient = networkClient
        self.configStore = configStore
    }

    func fetchBatch(offset: Int, limit: Int) async throws -> ShortsBatch {
        let config = await configStore.current(using: networkClient)
        let cohort = await DemoSessionStore.shared.currentCohort()
        let policyAttribute = await DemoSessionStore.shared.currentStorefrontPolicyAttribute()
        let pageNumber = max((offset / max(limit, 1)) + 1, 1)

        guard let request = Self.shortsRequest(
            config: config,
            cohort: cohort,
            policyAttribute: policyAttribute,
            pageNumber: pageNumber,
            pageSize: limit
        ) else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        let decoded = try JSONDecoder().decode(QuickplayContentResponseDTO.self, from: data)
        let posts = decoded.data
            .map { $0.toDomain(config: config) }
            .compactMap(ShortsPost.init(item:))

        return ShortsBatch(
            posts: posts,
            totalCount: decoded.header.count ?? posts.count,
            allVideoURLs: posts.map(\.videoURL)
        )
    }

    private static func shortsRequest(
        config: QuickplayRuntimeConfig,
        cohort: QuickplayCohort,
        policyAttribute: String,
        pageNumber: Int,
        pageSize: Int
    ) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.vodMetaDataURL)/content/urn/resource/catalog/shortvideo") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "info", value: "detail"),
            URLQueryItem(name: "mode", value: "detail"),
            URLQueryItem(name: "st", value: "published"),
            URLQueryItem(name: "dst", value: "published"),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "pageNumber", value: String(pageNumber)),
            URLQueryItem(name: "reg", value: AppEnvironment.Quickplay.region),
            URLQueryItem(name: "dt", value: AppEnvironment.Quickplay.deviceType),
            URLQueryItem(name: "client", value: AppEnvironment.Quickplay.client),
            URLQueryItem(name: "pf", value: cohort.profileFlag),
            URLQueryItem(name: "chrt", value: policyAttribute),
            URLQueryItem(name: "itvod", value: "true")
        ]

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.applyQuickplayHeaders()
        return request
    }
}

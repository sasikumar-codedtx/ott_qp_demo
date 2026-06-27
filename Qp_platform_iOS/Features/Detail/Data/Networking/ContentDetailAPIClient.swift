import Foundation

struct ContentDetailAPIClient {
    private let networkClient: NetworkClient
    private let configStore: QuickplayConfigurationStore

    init(
        networkClient: NetworkClient = NetworkClient(),
        configStore: QuickplayConfigurationStore = .shared
    ) {
        self.networkClient = networkClient
        self.configStore = configStore
    }

    func fetchDetail(itemID: String) async throws -> ContentDetailResponseDTO {
        let config = await configStore.current(using: networkClient)
        let cohort = await DemoSessionStore.shared.currentCohort()
        let policyAttribute = await DemoSessionStore.shared.currentStorefrontPolicyAttribute()
        guard let request = ContentDetailRouter.detailRequest(
            itemID: itemID,
            config: config,
            cohort: cohort,
            policyAttribute: policyAttribute
        ) else {
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
        let config = await configStore.current(using: networkClient)
        let cohort = await DemoSessionStore.shared.currentCohort()
        let policyAttribute = await DemoSessionStore.shared.currentStorefrontPolicyAttribute()
        guard let request = ContentDetailRouter.recommendationRequest(
            itemID: itemID,
            contentType: contentType,
            config: config,
            cohort: cohort,
            policyAttribute: policyAttribute
        ) else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            return try JSONDecoder().decode(RecommendationResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }

    func searchRecommendations(term: String) async throws -> SearchResponseDTO {
        let config = await configStore.current(using: networkClient)
        let cohort = await DemoSessionStore.shared.currentCohort()
        let policyAttribute = await DemoSessionStore.shared.currentStorefrontPolicyAttribute()
        guard let request = ContentDetailRouter.searchFallbackRequest(
            term: term,
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

    func searchMoments(contentID: String, term: String) async throws -> SearchResponseDTO {
        let config = await configStore.current(using: networkClient)
        let cohort = await DemoSessionStore.shared.currentCohort()
        let policyAttribute = await DemoSessionStore.shared.currentStorefrontPolicyAttribute()
        guard let request = ContentDetailRouter.momentSearchRequest(
            contentID: contentID,
            term: term,
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

    func fetchSeasons(seriesID: String) async throws -> ContentDetailResponseDTO {
        let config = await configStore.current(using: networkClient)
        let cohort = await DemoSessionStore.shared.currentCohort()
        let policyAttribute = await DemoSessionStore.shared.currentStorefrontPolicyAttribute()
        guard let request = ContentDetailRouter.seasonsRequest(
            seriesID: seriesID,
            config: config,
            cohort: cohort,
            policyAttribute: policyAttribute
        ) else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            return try JSONDecoder().decode(ContentDetailResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }

    func fetchEpisodes(seriesID: String, seasonID: String) async throws -> ContentDetailResponseDTO {
        let config = await configStore.current(using: networkClient)
        let cohort = await DemoSessionStore.shared.currentCohort()
        let policyAttribute = await DemoSessionStore.shared.currentStorefrontPolicyAttribute()
        guard let request = ContentDetailRouter.episodesRequest(
            seriesID: seriesID,
            seasonID: seasonID,
            config: config,
            cohort: cohort,
            policyAttribute: policyAttribute
        ) else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            return try JSONDecoder().decode(ContentDetailResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }
}

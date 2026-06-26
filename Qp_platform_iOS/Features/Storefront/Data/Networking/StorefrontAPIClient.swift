import Foundation

struct StorefrontAPIClient {
    private let networkClient: NetworkClient
    private let configStore: QuickplayConfigurationStore

    init(
        networkClient: NetworkClient = NetworkClient(),
        configStore: QuickplayConfigurationStore = .shared
    ) {
        self.networkClient = networkClient
        self.configStore = configStore
    }

    func fetchStorefront(cohort: QuickplayCohort) async throws -> QuickplayStorefrontResponseDTO {
        let config = await configStore.current(using: networkClient)
        guard let request = StorefrontRouter.storefrontRequest(config: config, cohort: cohort) else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            return try JSONDecoder().decode(QuickplayStorefrontResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }

    func fetchStorefront(from url: URL) async throws -> QuickplayStorefrontResponseDTO {
        let data = try await networkClient.data(for: StorefrontRouter.sourceRequest(url: url))
        do {
            return try JSONDecoder().decode(QuickplayStorefrontResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }
    func fetchContent(from url: URL) async throws -> QuickplayContentResponseDTO {
        let data = try await networkClient.data(for: StorefrontRouter.sourceRequest(url: url))
        do {
            return try JSONDecoder().decode(QuickplayContentResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }

    func fetchContentByIDs(cohort: QuickplayCohort, ids: [String], pageNumber: Int, pageSize: Int) async throws -> QuickplayContentResponseDTO {
        let config = await configStore.current(using: networkClient)
        guard let request = StorefrontRouter.sectionContentRequest(
            config: config,
            cohort: cohort,
            ids: ids,
            pageNumber: pageNumber,
            pageSize: pageSize
        ) else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            return try JSONDecoder().decode(QuickplayContentResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }

    func fetchCollectionLookup(cohort: QuickplayCohort, item: StorefrontItem, pageNumber: Int, pageSize: Int) async throws -> QuickplayContentResponseDTO {
        let config = await configStore.current(using: networkClient)
        guard let request = StorefrontRouter.collectionLookupRequest(
            config: config,
            cohort: cohort,
            item: item,
            pageNumber: pageNumber,
            pageSize: pageSize
        ) else {
            throw AppError.invalidURL
        }

        let data = try await networkClient.data(for: request)
        do {
            return try JSONDecoder().decode(QuickplayContentResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }

    func fetchContainers(
        cohort: QuickplayCohort,
        storefrontID: String,
        tabID: String,
        pageNumber: Int,
        pageSize: Int
    ) async throws -> QuickplayContainersResponseDTO {
        let config = await configStore.current(using: networkClient)
        guard let request = StorefrontRouter.containersRequest(
            config: config,
            cohort: cohort,
            storefrontID: storefrontID,
            tabID: tabID,
            pageNumber: pageNumber,
            pageSize: pageSize
        ) else {
            throw AppError.invalidURL
        }
        let data = try await networkClient.data(for: request)
        do {
            let response = try JSONDecoder().decode(QuickplayStorefrontResponseDTO.self, from: data)
            let storefront = response.data.first
            let selectedTab = storefront?.t?.first(where: { $0.id == tabID }) ??
                storefront?.t?.first(where: { ($0.c ?? []).isEmpty == false })
            return QuickplayContainersResponseDTO(
                header: response.header,
                data: selectedTab?.c ?? []
            )
        } catch {
            throw AppError.decodingFailed
        }
    }

    func fetchCollection(from url: URL) async throws -> QuickplayCollectionResponseDTO {
        let data = try await networkClient.data(for: StorefrontRouter.sourceRequest(url: url))
        do {
            return try JSONDecoder().decode(QuickplayCollectionResponseDTO.self, from: data)
        } catch {
            throw AppError.decodingFailed
        }
    }
}

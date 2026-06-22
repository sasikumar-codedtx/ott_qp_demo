import Foundation

actor QuickplayConfigurationStore {
    static let shared = QuickplayConfigurationStore()

    private var config = QuickplayRuntimeConfig.fallback
    private var hasLoaded = false

    func current(using networkClient: NetworkClient) async -> QuickplayRuntimeConfig {
        if !hasLoaded {
            try? await refresh(using: networkClient)
        }
        return config
    }

    func current() async -> QuickplayRuntimeConfig {
        await current(using: NetworkClient())
    }

    func refresh(using networkClient: NetworkClient) async throws {
        guard var components = URLComponents(string: AppEnvironment.Endpoint.launchConfigURL) else {
            throw AppError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "device", value: AppEnvironment.Quickplay.deviceType),
            URLQueryItem(name: "client", value: AppEnvironment.Quickplay.client)
        ]

        guard let url = components.url else {
            throw AppError.invalidURL
        }

        var request = URLRequest(url: url)
        request.applyQuickplayHeaders()

        let data = try await networkClient.data(for: request)
        let decoded = try JSONDecoder().decode(QuickplayLaunchConfigResponseDTO.self, from: data)
        config = QuickplayRuntimeConfig(entries: decoded.config)
        hasLoaded = true
    }

    func refresh() async throws {
        try await refresh(using: NetworkClient())
    }
}

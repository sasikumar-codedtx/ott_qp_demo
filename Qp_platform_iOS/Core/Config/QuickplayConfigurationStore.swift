import Foundation

actor QuickplayConfigurationStore {
    static let shared = QuickplayConfigurationStore()

    private var config = QuickplayRuntimeConfig.fallback
    private var hasLoaded = false
    private var loadTask: Task<QuickplayRuntimeConfig, Error>?

    func current(using networkClient: NetworkClient) async -> QuickplayRuntimeConfig {
        if hasLoaded {
            return config
        }

        if let loadTask {
            return (try? await loadTask.value) ?? config
        }

        let task = Task {
            try await Self.fetch(using: networkClient)
        }
        loadTask = task

        do {
            let loadedConfig = try await task.value
            config = loadedConfig
            hasLoaded = true
            loadTask = nil
        } catch {
            loadTask = nil
        }

        return config
    }

    func current() async -> QuickplayRuntimeConfig {
        await current(using: NetworkClient())
    }

    func refresh(using networkClient: NetworkClient) async throws {
        let loadedConfig = try await Self.fetch(using: networkClient)
        config = loadedConfig
        hasLoaded = true
        loadTask = nil
    }

    private static func fetch(using networkClient: NetworkClient) async throws -> QuickplayRuntimeConfig {
        guard var components = URLComponents(string: AppEnvironment.launchConfigURL) else {
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
        return QuickplayRuntimeConfig(entries: decoded.config)
    }

    func refresh() async throws {
        try await refresh(using: NetworkClient())
    }
}

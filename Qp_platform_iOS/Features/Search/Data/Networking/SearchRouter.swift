import Foundation

enum SearchRouter {
    static func makeRequest(term: String, config: QuickplayRuntimeConfig, cohort: QuickplayCohort) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.searchURL)/content/search") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "mode", value: "detail"),
            URLQueryItem(name: "st", value: "published"),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "pageNumber", value: "1"),
            URLQueryItem(name: "pageSize", value: AppEnvironment.Quickplay.searchPageSize),
            URLQueryItem(name: "reg", value: AppEnvironment.Quickplay.region),
            URLQueryItem(name: "dt", value: AppEnvironment.Quickplay.deviceType),
            URLQueryItem(name: "client", value: AppEnvironment.Quickplay.client),
            URLQueryItem(name: "pf", value: cohort.profileFlag),
            URLQueryItem(name: "chrt", value: AppEnvironment.Quickplay.cohort)
        ]

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.applyQuickplayHeaders()
        return request
    }
}

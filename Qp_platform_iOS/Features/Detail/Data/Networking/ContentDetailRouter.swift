import Foundation

enum ContentDetailRouter {
    static func detailRequest(itemID: String, config: QuickplayRuntimeConfig, cohort: QuickplayCohort) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.vodMetaDataURL)/content") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "ids", value: itemID),
            URLQueryItem(name: "mode", value: "detail"),
            URLQueryItem(name: "st", value: "published"),
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

    static func recommendationRequest(itemID: String, contentType: String, config: QuickplayRuntimeConfig, cohort: QuickplayCohort) -> URLRequest? {
        let payload: [String: Any] = [
            "item": itemID,
            "type": "more-like-this",
            "fields": [
                ["name": "dt", "values": [AppEnvironment.Quickplay.deviceType], "bias": 1],
                ["name": "reg", "values": [AppEnvironment.Quickplay.region], "bias": 1],
                ["name": "client", "values": [AppEnvironment.Quickplay.client], "bias": 1],
                ["name": "pf", "values": [cohort.profileFlag], "bias": 1],
                ["name": "chrt", "values": [AppEnvironment.Quickplay.cohort], "bias": 1],
                ["name": "cty", "values": [contentType], "bias": 1]
            ]
        ]

        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: payload),
            var components = URLComponents(string: "\(config.recommendURL)/recommend/lookup")
        else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: jsonData.base64EncodedString())
        ]

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.applyQuickplayHeaders()
        return request
    }

    static func searchFallbackRequest(term: String, config: QuickplayRuntimeConfig, cohort: QuickplayCohort) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.searchURL)/content/search") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "mode", value: "detail"),
            URLQueryItem(name: "st", value: "published"),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "pageNumber", value: "1"),
            URLQueryItem(name: "pageSize", value: "24"),
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

import Foundation

enum SearchRouter {
    static func makeRequest(
        term: String,
        facetTerm: String?,
        config: QuickplayRuntimeConfig,
        cohort: QuickplayCohort,
        policyAttribute: String
    ) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.searchURL)/content/search") else {
            return nil
        }

        var queryItems = [
            URLQueryItem(name: "client", value: AppEnvironment.Quickplay.client),
            URLQueryItem(name: "dt", value: AppEnvironment.Quickplay.deviceType),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "reg", value: AppEnvironment.Quickplay.region.lowercased()),
            URLQueryItem(name: "info", value: "detail"),
            URLQueryItem(name: "moment", value: "true"),
            URLQueryItem(name: "pf", value: cohort.profileFlag),
            URLQueryItem(name: "chrt", value: policyAttribute)
        ]

        if let facetTerm, facetTerm.isEmpty == false {
            queryItems.append(URLQueryItem(name: "cust_sc", value: facetTerm))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.applyQuickplayHeaders()
        return request
    }

}

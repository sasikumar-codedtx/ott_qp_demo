import Foundation

enum ContentDetailRouter {
    case detail(path: String)
    case recommendations(itemID: String, contentType: String)

    var urlRequest: URLRequest? {
        guard let url = makeURL() else { return nil }
        var request = URLRequest(url: url)
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue(AppEnvironment.webOrigin, forHTTPHeaderField: "Origin")
        request.setValue(AppEnvironment.webReferer, forHTTPHeaderField: "Referer")
        request.setValue(AppEnvironment.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func makeURL() -> URL? {
        switch self {
        case .detail(let path):
            var components = URLComponents(string: "\(AppEnvironment.Endpoint.detailBaseURL)/content/\(path)")
            components?.queryItems = [
                URLQueryItem(name: "reg", value: AppEnvironment.CatalogDefaults.region),
                URLQueryItem(name: "acl", value: AppEnvironment.CatalogDefaults.accessControl),
                URLQueryItem(name: "dt", value: AppEnvironment.CatalogDefaults.deviceType),
                URLQueryItem(name: "ipr", value: "true"),
                URLQueryItem(name: "itvod", value: "true"),
                URLQueryItem(name: "pf", value: AppEnvironment.CatalogDefaults.profile),
                URLQueryItem(name: "pl", value: AppEnvironment.CatalogDefaults.playbackLanguage)
            ]
            return components?.url

        case .recommendations(let itemID, let contentType):
            let payload: [String: Any] = [
                "item": itemID,
                "type": "more-like-this",
                "fields": [
                    ["name": "dt", "values": ["web"], "bias": 1],
                    ["name": "reg", "values": ["in"], "bias": 1],
                    ["name": "acl", "values": ["te,ta"], "bias": 1],
                    ["name": "pf", "values": ["profile"], "bias": 1],
                    ["name": "pl", "values": ["te,ta"], "bias": 1],
                    ["name": "cty", "values": [contentType], "bias": 1]
                ]
            ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
                return nil
            }

            let encoded = jsonData.base64EncodedString()
            var components = URLComponents(string: "\(AppEnvironment.Endpoint.recommendationBaseURL)/recommend/lookup")
            components?.queryItems = [URLQueryItem(name: "query", value: encoded)]
            return components?.url
        }
    }
}

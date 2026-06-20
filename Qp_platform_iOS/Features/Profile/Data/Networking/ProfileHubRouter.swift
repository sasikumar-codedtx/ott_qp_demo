import Foundation

enum ProfileHubRouter {
    case continueWatching
    case favorites
    case recommendations(profileID: String)

    var urlRequest: URLRequest? {
        guard let url = makeURL() else { return nil }
        var request = URLRequest(url: url)

        switch self {
        case .continueWatching, .favorites:
            request.applyAuthenticatedAhaHeaders(includeJSONContentType: true)
        case .recommendations:
            request.applyAhaHeaders()
        }

        return request
    }

    private func makeURL() -> URL? {
        switch self {
        case .continueWatching:
            var components = URLComponents(string: "\(AppEnvironment.Endpoint.bookmarkBaseURL)/user/bookmark/list")
            components?.queryItems = [
                URLQueryItem(name: "contentInfo", value: "true"),
                URLQueryItem(name: "pageSize", value: AppEnvironment.UserDefaults.pageSize),
                URLQueryItem(name: "reg", value: AppEnvironment.UserDefaults.region),
                URLQueryItem(name: "acl", value: AppEnvironment.UserDefaults.accessControl),
                URLQueryItem(name: "dt", value: AppEnvironment.UserDefaults.deviceType),
                URLQueryItem(name: "ipr", value: "true"),
                URLQueryItem(name: "itvod", value: "true"),
                URLQueryItem(name: "pf", value: AppEnvironment.UserDefaults.profile),
                URLQueryItem(name: "pl", value: AppEnvironment.UserDefaults.playbackLanguage)
            ]
            return components?.url

        case .favorites:
            var components = URLComponents(string: "\(AppEnvironment.Endpoint.favoriteBaseURL)/user/favorite/list")
            components?.queryItems = [
                URLQueryItem(name: "contentInfo", value: "true"),
                URLQueryItem(name: "pageSize", value: AppEnvironment.UserDefaults.pageSize),
                URLQueryItem(name: "reg", value: AppEnvironment.UserDefaults.region),
                URLQueryItem(name: "acl", value: AppEnvironment.UserDefaults.accessControl),
                URLQueryItem(name: "dt", value: AppEnvironment.UserDefaults.deviceType),
                URLQueryItem(name: "ipr", value: "true"),
                URLQueryItem(name: "itvod", value: "true"),
                URLQueryItem(name: "pf", value: AppEnvironment.UserDefaults.profile),
                URLQueryItem(name: "pl", value: AppEnvironment.UserDefaults.playbackLanguage)
            ]
            return components?.url

        case .recommendations(let profileID):
            let payload: [String: Any] = [
                "profileId": profileID,
                "type": "because-you-watched",
                "fields": [
                    ["name": "dt", "values": ["web"], "bias": 1],
                    ["name": "reg", "values": ["in"], "bias": 1],
                    ["name": "acl", "values": ["te,ta"], "bias": 1],
                    ["name": "pf", "values": ["profile"], "bias": 1],
                    ["name": "pl", "values": ["ta"], "bias": 1]
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

import Foundation

enum SearchRouter {
    case search(term: String)

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
        case .search(let term):
            var components = URLComponents(string: "\(AppEnvironment.Endpoint.searchBaseURL)/content/search")
            components?.queryItems = [
                URLQueryItem(name: "mode", value: "detail"),
                URLQueryItem(name: "st", value: "published"),
                URLQueryItem(name: "term", value: term),
                URLQueryItem(name: "pageNumber", value: "1"),
                URLQueryItem(name: "pageSize", value: AppEnvironment.SearchDefaults.pageSize),
                URLQueryItem(name: "reg", value: AppEnvironment.SearchDefaults.region),
                URLQueryItem(name: "acl", value: AppEnvironment.SearchDefaults.accessControl),
                URLQueryItem(name: "dt", value: AppEnvironment.SearchDefaults.deviceType),
                URLQueryItem(name: "ipr", value: "true"),
                URLQueryItem(name: "itvod", value: "true"),
                URLQueryItem(name: "pf", value: AppEnvironment.SearchDefaults.profile),
                URLQueryItem(name: "pl", value: AppEnvironment.SearchDefaults.playbackLanguage)
            ]
            return components?.url
        }
    }
}

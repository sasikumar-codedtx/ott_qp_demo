import Foundation

enum StorefrontRouter {
    case landing(storefrontID: String?, tabID: String?, pageNumber: Int)

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
        case let .landing(storefrontID, tabID, pageNumber):
            var components = URLComponents(string: "\(AppEnvironment.Endpoint.storefrontBaseURL)/catalog/storefront/landingscreen")
            components?.queryItems = [
                URLQueryItem(name: "ipr", value: "true"),
                URLQueryItem(name: "ivg", value: "false"),
                URLQueryItem(name: "sfInfo", value: "true"),
                URLQueryItem(name: "itvod", value: "true"),
                URLQueryItem(name: "acl", value: AppEnvironment.CatalogDefaults.accessControl),
                URLQueryItem(name: "reg", value: AppEnvironment.CatalogDefaults.region),
                URLQueryItem(name: "dt", value: AppEnvironment.CatalogDefaults.deviceType),
                URLQueryItem(name: "cPageNumber", value: String(pageNumber)),
                URLQueryItem(name: "cPageSize", value: AppEnvironment.CatalogDefaults.pageSize),
                URLQueryItem(name: "pf", value: AppEnvironment.CatalogDefaults.profile),
                URLQueryItem(name: "pl", value: AppEnvironment.CatalogDefaults.playbackLanguage)
            ]

            if let storefrontID {
                components?.queryItems?.append(URLQueryItem(name: "sfid", value: storefrontID))
            }

            if let tabID {
                components?.queryItems?.append(URLQueryItem(name: "tid", value: tabID))
            }

            return components?.url
        }
    }
}

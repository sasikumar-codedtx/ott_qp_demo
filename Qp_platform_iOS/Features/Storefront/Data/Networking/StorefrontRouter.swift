import Foundation

enum StorefrontRouter {
    static func storefrontRequest(config: QuickplayRuntimeConfig, cohort: QuickplayCohort) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.storefrontURL)/storefront/list") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "reg", value: AppEnvironment.Quickplay.storefrontProbeRegion),
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

    static func sourceRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.applyQuickplayHeaders()
        return request
    }

    static func sectionContentRequest(
        config: QuickplayRuntimeConfig,
        cohort: QuickplayCohort,
        ids: [String],
        pageNumber: Int,
        pageSize: Int
    ) -> URLRequest? {
        guard !ids.isEmpty else { return nil }
        guard var components = URLComponents(string: "\(config.vodMetaDataURL)/content") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
            URLQueryItem(name: "info", value: "detail"),
            URLQueryItem(name: "mode", value: "detail"),
            URLQueryItem(name: "st", value: "published"),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "pageNumber", value: String(pageNumber)),
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

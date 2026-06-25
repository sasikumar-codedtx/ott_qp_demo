import Foundation

enum StorefrontRouter {
    static func storefrontRequest(config: QuickplayRuntimeConfig, cohort: QuickplayCohort) -> URLRequest? {
        landingScreenRequest(config: config, cohort: cohort, storefrontID: nil, tabID: nil, pageNumber: 1, pageSize: 5)
    }

    static func landingScreenRequest(
        config: QuickplayRuntimeConfig,
        cohort: QuickplayCohort,
        storefrontID: String?,
        tabID: String?,
        pageNumber: Int,
        pageSize: Int
    ) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.catalogURL)/catalog/storefront/landingscreen") else {
            return nil
        }

        var queryItems = [
            URLQueryItem(name: "ipr", value: "true"),
            URLQueryItem(name: "ivg", value: "false"),
            URLQueryItem(name: "sfInfo", value: "true"),
            URLQueryItem(name: "reg", value: AppEnvironment.Quickplay.region.lowercased()),
            URLQueryItem(name: "dt", value: AppEnvironment.Quickplay.deviceType),
            URLQueryItem(name: "cPageNumber", value: String(pageNumber)),
            URLQueryItem(name: "cPageSize", value: String(pageSize)),
            URLQueryItem(name: "client", value: AppEnvironment.Quickplay.client),
            URLQueryItem(name: "pf", value: cohort.profileFlag),
            URLQueryItem(name: "chrt", value: AppEnvironment.Quickplay.cohort)
        ]
        if let storefrontID {
            queryItems.append(URLQueryItem(name: "sfid", value: storefrontID))
        }
        if let tabID {
            queryItems.append(URLQueryItem(name: "tid", value: tabID))
        }
        components.queryItems = queryItems

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

    static func containersRequest(
        config: QuickplayRuntimeConfig,
        cohort: QuickplayCohort,
        storefrontID: String,
        tabID: String,
        pageNumber: Int,
        pageSize: Int
    ) -> URLRequest? {
        landingScreenRequest(
            config: config,
            cohort: cohort,
            storefrontID: storefrontID,
            tabID: tabID,
            pageNumber: pageNumber,
            pageSize: pageSize
        )
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
            URLQueryItem(name: "pf", value: QuickplayCohort.entertainment.profileFlag),
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

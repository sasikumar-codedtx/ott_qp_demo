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

    static func recommendationRequest(itemID: String, contentType: String, config: QuickplayRuntimeConfig, cohort: QuickplayCohort) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.vodMetaDataURL)/content/morelikethis/\(itemID)") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "cty", value: contentType),
            URLQueryItem(name: "pageNumber", value: "1"),
            URLQueryItem(name: "pageSize", value: "10"),
            URLQueryItem(name: "client", value: AppEnvironment.Quickplay.client),
            URLQueryItem(name: "reg", value: AppEnvironment.Quickplay.region.lowercased()),
            URLQueryItem(name: "dt", value: "web")
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

    static func momentSearchRequest(contentID: String, term: String, config: QuickplayRuntimeConfig) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.searchURL)/content/search") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "client", value: AppEnvironment.Quickplay.client),
            URLQueryItem(name: "dt", value: AppEnvironment.Quickplay.deviceType),
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "reg", value: AppEnvironment.Quickplay.region.lowercased()),
            URLQueryItem(name: "info", value: "detail"),
            URLQueryItem(name: "moment", value: "true")
//            URLQueryItem(name: "id", value: contentID)
        ]

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.applyQuickplayHeaders()
        return request
    }

    static func seasonsRequest(seriesID: String, config: QuickplayRuntimeConfig, cohort: QuickplayCohort) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.vodMetaDataURL)/content/series/\(seriesID)/seasons") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "pageSize", value: "100"),
            URLQueryItem(name: "pageNumber", value: "1"),
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

    static func episodesRequest(seriesID: String, seasonID: String, config: QuickplayRuntimeConfig, cohort: QuickplayCohort) -> URLRequest? {
        guard var components = URLComponents(string: "\(config.vodMetaDataURL)/content/series/\(seriesID)/episodes") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "seasonId", value: seasonID),
            URLQueryItem(name: "pageSize", value: "100"),
            URLQueryItem(name: "pageNumber", value: "1"),
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

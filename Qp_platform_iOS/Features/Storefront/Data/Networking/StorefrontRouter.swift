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
        guard var components = URLComponents(string: "\(config.catalogURL)/catalog/storefront/\(storefrontID)/\(tabID)/containers") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "reg", value: AppEnvironment.Quickplay.region),
            URLQueryItem(name: "dt", value: AppEnvironment.Quickplay.deviceType),
            URLQueryItem(name: "client", value: AppEnvironment.Quickplay.client),
            URLQueryItem(name: "pf", value: cohort.profileFlag),
            URLQueryItem(name: "chrt", value: AppEnvironment.Quickplay.cohort),
            URLQueryItem(name: "policy_evaluate", value: "false"),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "pageNumber", value: String(pageNumber))
        ]

        guard let url = components.url else {
            return nil
        }

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
            URLQueryItem(name: "dst", value: "published"),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "reg", value: AppEnvironment.Quickplay.region),
            URLQueryItem(name: "dt", value: AppEnvironment.Quickplay.deviceType),
            URLQueryItem(name: "client", value: AppEnvironment.Quickplay.client),
            URLQueryItem(name: "pf", value: cohort.profileFlag),
            URLQueryItem(name: "chrt", value: AppEnvironment.Quickplay.cohort),
            URLQueryItem(name: "itvod", value: "true")
        ]

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.applyQuickplayHeaders()
        return request
    }

    static func collectionLookupRequest(
        config: QuickplayRuntimeConfig,
        cohort: QuickplayCohort,
        item: StorefrontItem,
        pageNumber: Int,
        pageSize: Int
    ) -> URLRequest? {
        let fallbackLookupQuery = CollectionLookupQueryBuilder.query(for: item)
        let sourceURL = item.collectionURL?.nilIfEmpty ?? "\(config.vodMetaDataURL)/content/lookup?query=\(fallbackLookupQuery)"
        guard var components = URLComponents(string: sourceURL) else {
            return nil
        }

        var queryItems = components.queryItems ?? []
        upsert(&queryItems, name: "info", value: "detail")
        upsert(&queryItems, name: "mode", value: "detail")
        upsert(&queryItems, name: "pageSize", value: String(pageSize))
        upsert(&queryItems, name: "pageNumber", value: String(pageNumber))
        upsert(&queryItems, name: "reg", value: AppEnvironment.Quickplay.region)
        upsert(&queryItems, name: "dt", value: AppEnvironment.Quickplay.deviceType)
        upsert(&queryItems, name: "client", value: AppEnvironment.Quickplay.client)
        upsert(&queryItems, name: "pf", value: cohort.profileFlag)
        upsert(&queryItems, name: "chrt", value: AppEnvironment.Quickplay.cohort)
        upsert(&queryItems, name: "itvod", value: "true")
        if queryItems.contains(where: { $0.name == "st" }) == false {
            queryItems.append(URLQueryItem(name: "st", value: "published"))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.applyQuickplayHeaders()
        return request
    }

    private static func upsert(_ queryItems: inout [URLQueryItem], name: String, value: String) {
        queryItems.removeAll { $0.name == name }
        queryItems.append(URLQueryItem(name: name, value: value))
    }
}

private enum CollectionLookupQueryBuilder {
    static func query(for item: StorefrontItem) -> String {
        let term = lookupTerm(for: item)
        var filters = [
            LookupFilter(field: "st", term: "published", operatorValue: "equals"),
            LookupFilter(field: "log.n", term: term, operatorValue: "equals")
        ]

        if let contentType = lookupContentType(for: item) {
            filters.append(LookupFilter(field: "cty", term: contentType, operatorValue: "equals"))
        }

        let payload = LookupPayload(filter: filters, match: "ALL")
        let data = (try? JSONEncoder().encode(payload)) ?? Data()
        return data.base64EncodedString()
    }

    private static func lookupTerm(for item: StorefrontItem) -> String {
        [
            item.customSearchCategory,
            item.genres.joined(separator: ",").nilIfEmpty,
            item.title.nilIfEmpty
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first(where: { !$0.isEmpty })?
        .lowercased() ?? item.title.lowercased()
    }

    private static func lookupContentType(for item: StorefrontItem) -> String? {
        let normalized = item.contentType
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        guard !normalized.isEmpty,
              normalized != "content",
              normalized != "collection",
              normalized != "view all",
              normalized != "viewall" else {
            return nil
        }

        return item.contentType
    }
}

private struct LookupPayload: Encodable {
    let filter: [LookupFilter]
    let match: String
}

private struct LookupFilter: Encodable {
    let field: String
    let term: String
    let operatorValue: String

    enum CodingKeys: String, CodingKey {
        case field
        case term
        case operatorValue = "operator"
    }
}

import Foundation

nonisolated struct QuickplayRuntimeConfig: Equatable, Sendable {
    let catalogURL: String
    let storefrontURL: String
    let vodMetaDataURL: String
    let searchURL: String
    let recommendURL: String
    let imageResizeURL: String
    let personalisationURL: String

    static let fallback = QuickplayRuntimeConfig(
        catalogURL: AppEnvironment.Endpoint.fallbackCatalogBaseURL,
        storefrontURL: AppEnvironment.Endpoint.fallbackStorefrontBaseURL,
        vodMetaDataURL: AppEnvironment.Endpoint.fallbackDetailBaseURL,
        searchURL: AppEnvironment.Endpoint.fallbackSearchBaseURL,
        recommendURL: AppEnvironment.Endpoint.fallbackRecommendationBaseURL,
        imageResizeURL: AppEnvironment.Endpoint.fallbackImageBaseURL,
        personalisationURL: AppEnvironment.Endpoint.fallbackPersonalisationBaseURL
    )
}

nonisolated struct QuickplayLaunchConfigResponseDTO: Decodable, Sendable {
    let config: [QuickplayLaunchConfigEntryDTO]
}

nonisolated struct QuickplayLaunchConfigEntryDTO: Decodable, Sendable {
    let key: String
    let value: QuickplayLaunchConfigValueDTO
}

nonisolated struct QuickplayLaunchConfigValueDTO: Decodable, Sendable {
    let rawValue: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            rawValue = string
            return
        }

        if let int = try? container.decode(Int.self) {
            rawValue = String(int)
            return
        }

        if let double = try? container.decode(Double.self) {
            rawValue = String(double)
            return
        }

        if let bool = try? container.decode(Bool.self) {
            rawValue = String(bool)
            return
        }

        rawValue = ""
    }
}

extension QuickplayRuntimeConfig {
    nonisolated init(entries: [QuickplayLaunchConfigEntryDTO]) {
        let values = Dictionary(uniqueKeysWithValues: entries.map { ($0.key, $0.value.rawValue) })
        let fallback = Self.fallback

        func resolvedValue(for key: String, fallback fallbackValue: String) -> String {
            let trimmed = values[key]?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (trimmed?.isEmpty == false ? trimmed : nil) ?? fallbackValue
        }

        self.init(
            catalogURL: resolvedValue(for: "catalogURL", fallback: fallback.catalogURL),
            storefrontURL: resolvedValue(for: "storefrontURL", fallback: fallback.storefrontURL),
            vodMetaDataURL: resolvedValue(for: "vodMetaDataURL", fallback: fallback.vodMetaDataURL),
            searchURL: resolvedValue(for: "searchURL", fallback: fallback.searchURL),
            recommendURL: resolvedValue(for: "recommendURL", fallback: fallback.recommendURL),
            imageResizeURL: resolvedValue(for: "imageResizeURL", fallback: fallback.imageResizeURL),
            personalisationURL: resolvedValue(for: "personalisationURL", fallback: fallback.personalisationURL)
        )
    }
}

import Foundation

nonisolated struct QuickplayRuntimeConfig: Equatable, Sendable {
    let catalogURL: String
    let storefrontURL: String
    let vodMetaDataURL: String
    let searchURL: String
    let recommendURL: String
    let imageResizeURL: String
    let personalisationURL: String
    let oauthURL: String
    let clientRegistrationURL: String
    let contentAuthURL: String
    let bookmarkURL: String
    let streamConcurrencyURL: String
    let favoriteURL: String
    let guestFlatURL: String
    let heartBeatURL: String
    let clientID: String
    let clientSecret: String
    let xClientID: String
    let defaultQpat: String
    let values: [String: String]

    static let fallback = QuickplayRuntimeConfig(
        catalogURL: "",
        storefrontURL: "",
        vodMetaDataURL: "",
        searchURL: "",
        recommendURL: "",
        imageResizeURL: "",
        personalisationURL: "",
        oauthURL: "",
        clientRegistrationURL: "",
        contentAuthURL: "",
        bookmarkURL: "",
        streamConcurrencyURL: "",
        favoriteURL: "",
        guestFlatURL: "",
        heartBeatURL: "",
        clientID: "",
        clientSecret: "",
        xClientID: "",
        defaultQpat: "",
        values: [:]
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
            personalisationURL: resolvedValue(for: "personalisationURL", fallback: fallback.personalisationURL),
            oauthURL: resolvedValue(for: "oAuthURL", fallback: fallback.oauthURL),
            clientRegistrationURL: resolvedValue(for: "clientRegURL", fallback: fallback.clientRegistrationURL),
            contentAuthURL: resolvedValue(for: "contentAuthURL", fallback: fallback.contentAuthURL),
            bookmarkURL: resolvedValue(for: "bookmarkURL", fallback: fallback.bookmarkURL),
            streamConcurrencyURL: resolvedValue(for: "strConcurrencyURL", fallback: fallback.streamConcurrencyURL),
            favoriteURL: resolvedValue(for: "favoriteURL", fallback: fallback.favoriteURL),
            guestFlatURL: resolvedValue(for: "guestFlatURL", fallback: fallback.guestFlatURL),
            heartBeatURL: resolvedValue(for: "heartBeatURL", fallback: fallback.heartBeatURL),
            clientID: resolvedValue(for: "clientID", fallback: fallback.clientID),
            clientSecret: resolvedValue(for: "clientSecret", fallback: fallback.clientSecret),
            xClientID: resolvedValue(for: "xClientId", fallback: fallback.xClientID),
            defaultQpat: resolvedValue(for: "defaultQpat", fallback: fallback.defaultQpat),
            values: values
        )
    }

    nonisolated func value(for key: String) -> String? {
        let trimmed = values[key]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}

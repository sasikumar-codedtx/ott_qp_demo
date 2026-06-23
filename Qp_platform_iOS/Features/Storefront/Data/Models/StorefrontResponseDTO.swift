import Foundation

struct APIHeaderDTO: Decodable {
    let code: Int
    let message: String
}

struct QuickplayStorefrontResponseDTO: Decodable {
    let header: APIHeaderDTO
    let data: [QuickplayStorefrontDTO]
}

struct QuickplayStorefrontDTO: Decodable {
    let id: String
    let ia: [String]?
    let iar: String?
    let lon: [LocalizedTextDTO]?
    let t: [QuickplayTabDTO]?
}

struct QuickplayTabDTO: Decodable {
    let id: String
    let lon: [LocalizedTextDTO]?
    let c: [QuickplayContainerDTO]?
}

struct QuickplayContainerDTO: Decodable {
    let id: String
    let iar: String?
    let lo: String?
    let lon: [LocalizedTextDTO]?
    let srcType: String?
    let i: [QuickplayContentSourceDTO]?
    let diar: [QuickplayImageAspectDTO]?

    enum CodingKeys: String, CodingKey {
        case id
        case iar
        case lo
        case lon
        case i
        case diar
        case srcType = "src_ty"
    }

    var preferredRatio: String {
        diar?.first(where: { $0.device == "mobile" })?.ratio ??
        diar?.first?.ratio ??
        iar ??
        "0-2x3"
    }
}

struct QuickplayContentSourceDTO: Decodable {
    let count: Int?
    let cu: String?
    let priority: Int?
    let type: String?

    func normalizedURL(config: QuickplayRuntimeConfig, cohort: QuickplayCohort) -> URL? {
        guard let cu, let rawURL = URL(string: cu), var components = URLComponents(url: rawURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let targetBaseURL: String
        if cu.contains("/storefront/list") {
            targetBaseURL = config.storefrontURL
        } else {
            targetBaseURL = config.vodMetaDataURL
        }

        guard let baseURL = URL(string: targetBaseURL), let baseComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.scheme = baseComponents.scheme
        components.host = baseComponents.host
        components.port = baseComponents.port

        var queryItems = components.queryItems ?? []
        upsert(&queryItems, name: "reg", value: AppEnvironment.Quickplay.region)
        upsert(&queryItems, name: "dt", value: AppEnvironment.Quickplay.deviceType)
        upsert(&queryItems, name: "client", value: AppEnvironment.Quickplay.client)
        upsert(&queryItems, name: "pf", value: cohort.profileFlag)
        upsert(&queryItems, name: "chrt", value: AppEnvironment.Quickplay.cohort)
        if queryItems.contains(where: { $0.name == "mode" }) == false {
            queryItems.append(URLQueryItem(name: "mode", value: "detail"))
        }
        if queryItems.contains(where: { $0.name == "st" }) == false {
            queryItems.append(URLQueryItem(name: "st", value: "published"))
        }
        components.queryItems = queryItems
        return components.url
    }

    private func upsert(_ queryItems: inout [URLQueryItem], name: String, value: String) {
        queryItems.removeAll(where: { $0.name == name })
        queryItems.append(URLQueryItem(name: name, value: value))
    }
}

struct QuickplayImageAspectDTO: Decodable {
    let device: String?
    let ratio: String?

    enum CodingKeys: String, CodingKey {
        case device = "dt"
        case ratio = "iar"
    }
}

struct QuickplayContentResponseDTO: Decodable {
    let header: APIHeaderDTO
    let data: [QuickplayContentItemDTO]
}

struct QuickplayCollectionResponseDTO: Decodable {
    let header: APIHeaderDTO
    let data: [QuickplayCollectionItemDTO]
}

struct QuickplayContentItemDTO: Decodable {
    let id: String
    let cty: String?
    let lon: [LocalizedTextDTO]?
    let lod: [LocalizedTextDTO]?
    let log: [LocalizedTextListDTO]?
    let ph: [LocalizedTextListDTO]?
    let rat: [StorefrontRatingDTO]?
    let ia: [String]?
    let pt: String?
    let ad: FlexibleBoolDTO?
    let ae: FlexibleBoolDTO?
    let vq: String?
    let rt: Int?
    let apURL: String?
    let nu: String?
    let urn: String?
    let locs: [ContentPersonDTO]?
    let lodr: [ContentPersonDTO]?
    let vsm: [ContentMomentsDTO]?
    let yearDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case cty
        case lon
        case lod
        case log
        case ph
        case rat
        case ia
        case pt
        case ad
        case ae
        case vq
        case rt
        case apURL = "ap_url"
        case nu
        case urn
        case locs
        case lodr
        case vsm = "v_sm"
        case yearDate = "rdt"
    }

    func toDomain(config: QuickplayRuntimeConfig, progress: Double? = nil) -> StorefrontItem {
        StorefrontItem(
            id: id,
            title: lon?.preferredText ?? "Untitled",
            description: lod?.preferredText ?? "",
            contentType: cty ?? "content",
            slug: nu,
            resourceURN: urn,
            year: yearDate.flatMap { String($0.prefix(4)) },
            genres: log?.preferredList ?? [],
            rating: rat?.first?.v,
            isPremium: pt == "SVOD",
            quality: vq,
            availableRatios: ia ?? [],
            runtimeSeconds: rt,
            progress: progress,
            canOpenDetail: true,
            previewURL: apURL.flatMap(URL.init(string:)),
            imageBaseURL: config.imageResizeURL
        )
    }

    func toDetailDomain(config: QuickplayRuntimeConfig) -> ContentDetail {
        ContentDetail(
            id: id,
            title: lon?.preferredText ?? "Untitled",
            description: lod?.preferredText ?? "",
            contentType: cty ?? "content",
            year: yearDate.flatMap { String($0.prefix(4)) },
            genres: log?.preferredList ?? [],
            rating: rat?.first?.v,
            runtimeSeconds: rt,
            quality: vq,
            isPremium: pt == "SVOD",
            hasFreePreview: ad?.value == true || ae?.value == true,
            sponsorNames: ph?.preferredList ?? [],
            availableRatios: ia ?? [],
            cast: (locs ?? []).map { $0.toDomain(config: config) },
            directorNames: (lodr ?? []).map(\.localizedName),
            momentSearchEnabled: (vsm ?? []).contains(where: { $0.ff?.value == true }),
            previewURL: apURL.flatMap(URL.init(string:)),
            imageBaseURL: config.imageResizeURL
        )
    }
}

struct QuickplayCollectionItemDTO: Decodable {
    let id: String
    let ia: [String]?
    let lon: [LocalizedTextDTO]?

    func toDomain(config: QuickplayRuntimeConfig) -> StorefrontItem {
        StorefrontItem(
            id: id,
            title: lon?.preferredText ?? "Untitled",
            description: "",
            contentType: "collection",
            slug: nil,
            resourceURN: nil,
            year: nil,
            genres: [],
            rating: nil,
            isPremium: false,
            quality: nil,
            availableRatios: ia ?? ["0-1x1"],
            runtimeSeconds: nil,
            progress: nil,
            canOpenDetail: false,
            previewURL: nil,
            imageBaseURL: config.imageResizeURL
        )
    }
}

struct LocalizedTextDTO: Decodable {
    let lang: String?
    let n: String
}

struct LocalizedTextListDTO: Decodable {
    let lang: String?
    let n: [String]
}

struct StorefrontRatingDTO: Decodable {
    let cc: String?
    let s: String?
    let v: String
}

struct FlexibleBoolDTO: Decodable {
    let value: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
            return
        }

        if let string = try? container.decode(String.self) {
            value = string.lowercased() == "true"
            return
        }

        if let int = try? container.decode(Int.self) {
            value = int != 0
            return
        }

        value = false
    }
}

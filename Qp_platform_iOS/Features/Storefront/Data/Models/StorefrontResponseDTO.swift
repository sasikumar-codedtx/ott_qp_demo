import Foundation

struct StorefrontResponseDTO: Decodable {
    let data: StorefrontDataDTO
}

struct StorefrontDataDTO: Decodable {
    let id: String
    let t: [StorefrontTabDTO]
}

struct StorefrontTabDTO: Decodable {
    let id: String
    let lon: [LocalizedTextDTO]?
    let c: [StorefrontSectionDTO]?
    let pagination: StorefrontPaginationDTO?
}

struct StorefrontSectionDTO: Decodable {
    let id: String
    let iar: String?
    let lon: [LocalizedTextDTO]?
    let cd: [StorefrontItemDTO]?
}

struct StorefrontItemDTO: Decodable {
    let id: String
    let cty: String?
    let lon: [LocalizedTextDTO]?
    let lod: [LocalizedTextDTO]?
    let log: [LocalizedTextListDTO]?
    let ph: [LocalizedTextListDTO]?
    let rat: [StorefrontRatingDTO]?
    let ia: [String]?
    let pt: String?
    let ape: FlexibleBoolDTO?
    let ao: FlexibleBoolDTO?
    let vq: String?
    let r: Int?
    let rt: Int?
    let nu: String?
    let urn: String?

    func toDomain(progress: Double? = nil) -> StorefrontItem {
        StorefrontItem(
            id: id,
            title: lon?.preferredText ?? "Untitled",
            description: lod?.preferredText ?? "",
            contentType: cty ?? "content",
            slug: nu,
            resourceURN: urn,
            year: r.map(String.init),
            genres: log?.preferredList ?? [],
            rating: rat?.first?.v,
            isPremium: pt == "SVOD" || ape?.value == true || ao?.value == false,
            quality: vq,
            availableRatios: ia ?? [],
            runtimeSeconds: rt,
            progress: progress
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

struct StorefrontPaginationDTO: Decodable {
    let start: Int
    let rows: Int
    let count: Int
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

struct AhaHeaderDTO: Decodable {
    let code: Int
    let message: String
}

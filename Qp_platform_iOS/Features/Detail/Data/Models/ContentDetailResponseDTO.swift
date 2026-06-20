import Foundation

struct ContentDetailResponseDTO: Decodable {
    let header: AhaHeaderDTO
    let data: ContentDetailDTO
}

struct ContentDetailDTO: Decodable {
    let id: String
    let cty: String
    let lon: [LocalizedTextDTO]?
    let lod: [LocalizedTextDTO]?
    let log: [LocalizedTextListDTO]?
    let ph: [LocalizedTextListDTO]?
    let rat: [StorefrontRatingDTO]?
    let ia: [String]?
    let pt: String?
    let ao: FlexibleBoolDTO?
    let ape: FlexibleBoolDTO?
    let apeDetail: FlexibleBoolDTO?
    let apteDetail: FlexibleBoolDTO?
    let vq: String?
    let r: Int?
    let rt: Int?
    let locs: [ContentPersonDTO]?
    let lodr: [ContentPersonDTO]?
    let vsm: ContentMomentsDTO?

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
        case ao
        case ape
        case apeDetail = "ape_detail"
        case apteDetail = "apte_detail"
        case vq
        case r
        case rt
        case locs
        case lodr
        case vsm = "v_sm"
    }

    func toDomain() -> ContentDetail {
        ContentDetail(
            id: id,
            title: lon?.preferredText ?? "Untitled",
            description: lod?.preferredText ?? "",
            contentType: cty,
            year: r.map(String.init),
            genres: log?.preferredList ?? [],
            rating: rat?.first?.v,
            runtimeSeconds: rt,
            quality: vq,
            isPremium: pt == "SVOD" || ao?.value == true,
            hasFreePreview: ape?.value == true || apeDetail?.value == true || apteDetail?.value == true,
            sponsorNames: ph?.preferredList ?? [],
            availableRatios: ia ?? [],
            cast: (locs ?? []).map { $0.toDomain() },
            directorNames: (lodr ?? []).map { $0.localizedName },
            momentSearchEnabled: vsm?.rs?.value == true
        )
    }
}

struct ContentPersonDTO: Decodable {
    let id: String
    let ia: [String]?
    let lon: [LocalizedTextDTO]?

    var localizedName: String {
        lon?.preferredText ?? "Unknown"
    }

    func toDomain() -> ContentPerson {
        ContentPerson(id: id, name: localizedName, imageRatios: ia ?? [])
    }
}

struct ContentMomentsDTO: Decodable {
    let rs: FlexibleBoolDTO?
}

import Foundation

typealias ContentDetailResponseDTO = QuickplayContentResponseDTO

struct ContentPersonDTO: Decodable {
    let id: String?
    let ia: [String]?
    let lon: [LocalizedTextDTO]?
    let imagePath: String?
    let imagePathSnake: String?
    let nu: String?
    let updatedTime: String?
    let updatedTimeSnake: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ia
        case lon
        case imagePath
        case imagePathSnake = "image_path"
        case nu
        case updatedTime
        case updatedTimeSnake = "updated_time"
    }

    var localizedName: String {
        lon?.preferredText ?? "Unknown"
    }

    func toDomain(config: QuickplayRuntimeConfig) -> ContentPerson {
        ContentPerson(
            id: id ?? UUID().uuidString,
            name: localizedName,
            imageRatios: ia ?? [],
            imageBaseURL: config.imageResizeURL,
            imagePath: imagePath?.nilIfEmpty ?? imagePathSnake?.nilIfEmpty ?? nu?.nilIfEmpty,
            updatedTime: updatedTime?.nilIfEmpty ?? updatedTimeSnake?.nilIfEmpty
        )
    }
}

struct ContentMomentsDTO: Decodable {
    let ff: FlexibleBoolDTO?
}

struct RawMarkerDTO: Decodable {
    let m_st: Double?
    let m_ed: Double?
    let t: String?
}

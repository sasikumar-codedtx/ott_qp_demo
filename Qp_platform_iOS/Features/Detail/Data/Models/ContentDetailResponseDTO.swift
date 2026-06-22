import Foundation

typealias ContentDetailResponseDTO = QuickplayContentResponseDTO

struct ContentPersonDTO: Decodable {
    let id: String?
    let ia: [String]?
    let lon: [LocalizedTextDTO]?

    var localizedName: String {
        lon?.preferredText ?? "Unknown"
    }

    func toDomain() -> ContentPerson {
        ContentPerson(
            id: id ?? UUID().uuidString,
            name: localizedName,
            imageRatios: ia ?? []
        )
    }
}

struct ContentMomentsDTO: Decodable {
    let ff: FlexibleBoolDTO?
}

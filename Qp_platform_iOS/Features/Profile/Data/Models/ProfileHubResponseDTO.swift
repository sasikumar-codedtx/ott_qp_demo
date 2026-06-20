import Foundation

struct AuthenticatedContentRailResponseDTO: Decodable {
    let header: AhaHeaderDTO
    let data: [AuthenticatedContentRailItemDTO]
}

struct AuthenticatedContentRailItemDTO: Decodable {
    let info: StorefrontItemDTO?
    let itemId: String?
    let offset: Int?
    let ut: Int?

    func toDomain() -> StorefrontItem? {
        guard let info else { return nil }

        let durationMilliseconds = Double((info.rt ?? 0) * 1000)
        let progress: Double?
        if let offset, durationMilliseconds > 0 {
            progress = Double(offset) / durationMilliseconds
        } else {
            progress = nil
        }

        return info.toDomain(progress: progress)
    }
}

import Foundation

struct RecommendationResponseDTO: Decodable {
    let header: AhaHeaderDTO
    let data: [StorefrontItemDTO]
}

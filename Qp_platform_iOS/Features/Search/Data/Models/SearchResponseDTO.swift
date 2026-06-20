import Foundation

struct SearchResponseDTO: Decodable {
    let header: AhaHeaderDTO
    let data: [StorefrontItemDTO]
}

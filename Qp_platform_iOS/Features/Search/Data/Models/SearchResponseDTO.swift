import Foundation

struct SearchResponseDTO: Decodable {
    let header: APIHeaderDTO
    let data: [QuickplayContentItemDTO]
    let facet: SearchFacetDTO?
}

struct SearchFacetDTO: Decodable {
    let field: String?
    let terms: [SearchFacetTermDTO]?
}

struct SearchFacetTermDTO: Decodable {
    let count: Int?
    let term: String?
}

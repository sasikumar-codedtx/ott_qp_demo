import Foundation

extension Array where Element == LocalizedTextDTO {
    var preferredText: String {
        first(where: { $0.lang == "en" })?.n ?? first?.n ?? ""
    }
}

extension Array where Element == LocalizedTextListDTO {
    var preferredList: [String] {
        first(where: { $0.lang == "en" })?.n ?? first?.n ?? []
    }
}

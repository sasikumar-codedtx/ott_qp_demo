import Foundation

extension URLRequest {
    nonisolated mutating func applyQuickplayHeaders(includeJSONContentType: Bool = false) {
       
        if includeJSONContentType {
            setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }
}

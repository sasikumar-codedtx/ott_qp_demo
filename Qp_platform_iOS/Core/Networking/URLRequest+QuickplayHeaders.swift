import Foundation

extension URLRequest {
    nonisolated mutating func applyQuickplayHeaders(includeJSONContentType: Bool = false) {
        setValue("*/*", forHTTPHeaderField: "Accept")
        setValue(AppEnvironment.webOrigin, forHTTPHeaderField: "Origin")
        setValue(AppEnvironment.webReferer, forHTTPHeaderField: "Referer")
        setValue(AppEnvironment.userAgent, forHTTPHeaderField: "User-Agent")

        if includeJSONContentType {
            setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }
}

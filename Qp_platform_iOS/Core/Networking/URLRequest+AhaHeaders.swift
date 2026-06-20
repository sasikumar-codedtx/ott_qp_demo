import Foundation

extension URLRequest {
    mutating func applyAhaHeaders(includeJSONContentType: Bool = false) {
        setValue("*/*", forHTTPHeaderField: "Accept")
        setValue(AppEnvironment.webOrigin, forHTTPHeaderField: "Origin")
        setValue(AppEnvironment.webReferer, forHTTPHeaderField: "Referer")
        setValue(AppEnvironment.userAgent, forHTTPHeaderField: "User-Agent")

        if includeJSONContentType {
            setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }

    mutating func applyAuthenticatedAhaHeaders(includeJSONContentType: Bool = false) {
        applyAhaHeaders(includeJSONContentType: includeJSONContentType)
        setValue("Bearer \(AppEnvironment.AuthSession.accessToken)", forHTTPHeaderField: "Authorization")
        setValue(AppEnvironment.AuthSession.xAuthorization, forHTTPHeaderField: "X-Authorization")
    }
}

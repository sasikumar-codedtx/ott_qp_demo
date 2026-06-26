import Foundation

struct NetworkClient: Sendable {
    nonisolated init() {}

    nonisolated func data(for request: URLRequest) async throws -> Data {
        NetworkLogger.logRequest(request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            NetworkLogger.logFailure(request: request, error: error)
            throw error
        }
//        NetworkLogger.logResponse(request: request, data: data, response: response)

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AppError.invalidResponse
        }
        return data
    }
}

enum NetworkLogger {
    nonisolated private static let redactedHeaderNames = Set([
        "authorization",
        "x-authorization",
        "cookie",
        "set-cookie"
    ])

    nonisolated static func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<missing-url>"
        let headers = redactedHeaders(request.allHTTPHeaderFields ?? [:])
        let body = bodyPreview(request.httpBody)

        print("""

        [Network][Request]
        \(method) \(url)
        headers: \(headers)
        body: \(body)
        """)
    }

    nonisolated static func logResponse(request: URLRequest, data: Data, response: URLResponse) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<missing-url>"
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? -1
        let headers = redactedHeaders(httpResponse?.allHeaderFields ?? [:])
        let body = bodyPreview(data)

        print("""

        [Network][Response]
        \(method) \(url)
        status: \(statusCode)
        headers: \(headers)
        body: \(body)
        """)
    }

    nonisolated static func logFailure(request: URLRequest, error: Error) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "<missing-url>"

        print("""

        [Network][Failure]
        \(method) \(url)
        error: \(error.localizedDescription)
        """)
    }

    nonisolated private static func redactedHeaders(_ headers: [AnyHashable: Any]) -> [String: String] {
        headers.reduce(into: [:]) { result, entry in
            let key = String(describing: entry.key)
            let value = redactedHeaderNames.contains(key.lowercased())
                ? "<redacted>"
                : String(describing: entry.value)
            result[key] = value
        }
    }

    nonisolated private static func redactedHeaders(_ headers: [String: String]) -> [String: String] {
        headers.reduce(into: [:]) { result, entry in
            result[entry.key] = redactedHeaderNames.contains(entry.key.lowercased())
                ? "<redacted>"
                : entry.value
        }
    }

    nonisolated private static func bodyPreview(_ data: Data?) -> String {
        guard let data, !data.isEmpty else { return "<empty>" }

        let string: String
        if
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
            let prettyString = String(data: prettyData, encoding: .utf8)
        {
            string = prettyString
        } else {
            string = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
        }

        return string
    }
}

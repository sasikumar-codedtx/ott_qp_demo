import Foundation

nonisolated struct ImageURLBuilder: Sendable {
    let baseURL: String

    func imageURL(id: String, ratio: String, availableRatios: [String], width: Int, preferredFallbacks: [String]) -> URL? {
        let resolvedRatio = availableRatios.contains(ratio)
            ? ratio
            : (preferredFallbacks.first(where: { availableRatios.contains($0) }) ?? ratio)

        let trimmedBaseURL = baseURL.trimmingTrailingSlashes()
        return URL(string: "\(trimmedBaseURL)/image/\(id)/\(resolvedRatio).png?width=\(width)")
    }
}

private extension String {
    nonisolated func trimmingTrailingSlashes() -> String {
        var value = trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasSuffix("/") {
            value.removeLast()
        }
        return value
    }
}

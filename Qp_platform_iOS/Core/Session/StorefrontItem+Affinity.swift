import Foundation

extension StorefrontItem {
    nonisolated var inferredPreference: ProfilePreference {
        let searchableTerms = ([contentType] + genres + [title, description]).map { $0.lowercased() }
        let type = contentType.lowercased()

        if containsAny(in: searchableTerms, keywords: ["sport", "cricket", "football", "kabaddi", "wwe", "match", "tournament"]) ||
            type.contains("sport") ||
            type.contains("match") ||
            type.contains("live") ||
            type.contains("channel")
        {
            return .sports
        }

        if containsAny(in: searchableTerms, keywords: ["reality", "unscripted", "talent", "game show", "competition"]) {
            return .realityShows
        }

        if containsAny(in: searchableTerms, keywords: ["micro", "microdrama", "micro drama", "snackable", "short drama"]) ||
            type.contains("micro")
        {
            return .microdramas
        }

        return .entertainment
    }

    private nonisolated func containsAny(in terms: [String], keywords: [String]) -> Bool {
        terms.contains { term in
            keywords.contains { keyword in term.localizedCaseInsensitiveContains(keyword) }
        }
    }
}

import Foundation

enum DemoRailComposer {
    static func continueWatching(from items: [StorefrontItem], limit: Int = 10) -> [StorefrontItem] {
        Array(items.prefix(limit))
    }

    static func favorites(from items: [StorefrontItem], limit: Int = 10) -> [StorefrontItem] {
        let preferred = items.filter { $0.availableRatios.contains("0-2x3") || $0.availableRatios.contains("0-1x1") }
        return Array((preferred.isEmpty ? items : preferred).prefix(limit))
    }

    static func recommendations(from items: [StorefrontItem], excluding excludedID: String? = nil, limit: Int = 12) -> [StorefrontItem] {
        let filtered = items.filter { item in
            guard let excludedID else { return true }
            return item.id != excludedID
        }

        let preferred = filtered.filter { $0.availableRatios.contains("0-2x3") || $0.availableRatios.contains("0-16x9") }
        return Array((preferred.isEmpty ? filtered : preferred).prefix(limit))
    }
}

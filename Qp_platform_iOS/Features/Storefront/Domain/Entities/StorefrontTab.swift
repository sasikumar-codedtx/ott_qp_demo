import Foundation

struct StorefrontTab: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
}

struct StorefrontPage: Equatable {
    let storefrontID: String
    let tabs: [StorefrontTab]
    let selectedTabID: String
    let sections: [StorefrontSection]
    let nextPage: Int
    let loadedCount: Int
    let totalCount: Int

    var hasMore: Bool {
        loadedCount < totalCount
    }
}

import Combine
import Foundation

@MainActor
final class ShortsFeedViewModel: ObservableObject {
    @Published private(set) var visiblePosts: [ShortsPost] = []
    @Published var currentPostID: ShortsPost.ID?
    @Published private(set) var isMuted = true
    @Published private(set) var likedPostIDs: Set<ShortsPost.ID> = []
    @Published private(set) var favoritePostIDs: Set<ShortsPost.ID> = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoadingInitial = false

    private let useCase: GetShortsBatchUseCase
    private let bufferManager: ShortsVideoBufferManager
    private let batchSize = 10
    private let fullBufferTriggerIndex = 5

    private var totalCount = 0
    private var catalogPosts: [ShortsPost] = []
    private var catalogVideoURLs: [URL] = []
    private var isLoadingBatch = false
    private var hasLoadedInitialBatch = false

    init(useCase: GetShortsBatchUseCase, bufferManager: ShortsVideoBufferManager? = nil) {
        self.useCase = useCase
        self.bufferManager = bufferManager ?? .shared
    }

    func loadInitialBatchIfNeeded() async {
        guard !hasLoadedInitialBatch else { return }

        hasLoadedInitialBatch = true
        isLoadingInitial = true
        await loadNextBatch()
        isLoadingInitial = false
        currentPostID = visiblePosts.first?.id
        await refreshSessionState()

        let startupURLs = Array(visiblePosts.prefix(3)).map(\.videoURL)
        bufferManager.preload(urls: startupURLs, mode: .nearby)
    }

    func prefetchForActiveProfile() async {
        await reload()
    }

    func open(startingWith item: StorefrontItem?) async {
        if let item, let post = ShortsPost(item: item) {
            visiblePosts.removeAll { $0.id == post.id }
            visiblePosts.insert(post, at: 0)
            currentPostID = post.id
            bufferManager.preload(urls: [post.videoURL], mode: .nearby)
        }

        if !hasLoadedInitialBatch {
            hasLoadedInitialBatch = true
            isLoadingInitial = visiblePosts.isEmpty
            await loadNextBatch()
            isLoadingInitial = false
            if currentPostID == nil {
                currentPostID = visiblePosts.first?.id
            }
        }

        await refreshSessionState()
        preloadWindow(around: visiblePosts.firstIndex(where: { $0.id == currentPostID }) ?? 0)
    }

    /// Seeds the feed from a specific set of items (a rail / collection / view-all),
    /// starting at the tapped one, and loops through them without hitting the global
    /// shorts API. Used by the dedicated shorts player pushed from the storefront.
    func present(items: [StorefrontItem], startingAt startItem: StorefrontItem) {
        var posts = items.compactMap(ShortsPost.init(item:))
        if posts.isEmpty, let single = ShortsPost(item: startItem) {
            posts = [single]
        }
        guard !posts.isEmpty else { return }

        // Put the tapped short first so the feed opens on it.
        if let index = posts.firstIndex(where: { $0.id == startItem.id }), index != 0 {
            let start = posts.remove(at: index)
            posts.insert(start, at: 0)
        }

        visiblePosts = posts
        catalogPosts = posts
        catalogVideoURLs = posts.map(\.videoURL)
        totalCount = posts.count          // catalog is "complete" → loops, never fetches the API
        hasLoadedInitialBatch = true
        isLoadingBatch = false
        isLoadingInitial = false
        errorMessage = nil
        likedPostIDs = []
        favoritePostIDs = []
        currentPostID = posts.first?.id

        bufferManager.preload(urls: Array(posts.prefix(3)).map(\.videoURL), mode: .nearby)
        Task { await refreshSessionState() }
    }

    func reload() async {
        visiblePosts = []
        currentPostID = nil
        likedPostIDs = []
        favoritePostIDs = []
        errorMessage = nil
        isLoadingInitial = false
        totalCount = 0
        catalogPosts = []
        catalogVideoURLs = []
        isLoadingBatch = false
        hasLoadedInitialBatch = false
        await loadInitialBatchIfNeeded()
    }

    func handleVisiblePostChange(_ postID: ShortsPost.ID?) {
        guard
            let postID,
            let currentIndex = visiblePosts.firstIndex(where: { $0.id == postID })
        else {
            return
        }

        preloadWindow(around: currentIndex)

        if currentIndex >= visiblePosts.count - 5 {
            Task {
                await loadNextBatch()
            }
        }

        if currentIndex >= fullBufferTriggerIndex {
            Task {
                guard await bufferManager.shouldStartFullFeedBuffering() else { return }
                bufferManager.preload(urls: catalogVideoURLs, mode: .fullFeed)
            }
        }
    }

    func toggleMute() {
        isMuted.toggle()
    }

    func like(postID: ShortsPost.ID) {
        guard let post = visiblePosts.first(where: { $0.id == postID }) else { return }
        guard let item = post.sourceItem else {
            if likedPostIDs.contains(postID) {
                likedPostIDs.remove(postID)
            } else {
                likedPostIDs.insert(postID)
            }
            return
        }

        Task {
            let state = await DemoSessionStore.shared.cycleLike(for: item)
            if state == .liked {
                likedPostIDs.insert(postID)
            } else {
                likedPostIDs.remove(postID)
            }
        }
    }

    func toggleFavorite(postID: ShortsPost.ID) {
        guard
            let post = visiblePosts.first(where: { $0.id == postID }),
            let item = post.sourceItem
        else {
            return
        }

        Task {
            let isFavorite = await DemoSessionStore.shared.toggleFavorite(item)
            if isFavorite {
                favoritePostIDs.insert(postID)
            } else {
                favoritePostIDs.remove(postID)
            }
        }
    }

    private func preloadWindow(around currentIndex: Int) {
        guard !visiblePosts.isEmpty else { return }

        let lowerBound = max(0, currentIndex - 1)
        let upperBound = min(visiblePosts.count - 1, currentIndex + 3)
        let urls = Array(visiblePosts[lowerBound...upperBound]).map(\.videoURL)
        bufferManager.preload(urls: urls, mode: .nearby)
    }

    private func loadNextBatch() async {
        guard !isLoadingBatch else { return }
        isLoadingBatch = true
        defer { isLoadingBatch = false }

        do {
            if shouldFetchMoreCatalog {
                let batch = try await useCase.execute(offset: catalogPosts.count, limit: batchSize)
                totalCount = batch.totalCount
                appendToCatalog(batch.posts)
                catalogVideoURLs = catalogPosts.map(\.videoURL)
            }
            errorMessage = nil

            let nextPosts = nextCircularPosts(count: batchSize)
            guard !nextPosts.isEmpty else { return }
            visiblePosts.append(contentsOf: nextPosts)
            await refreshSessionState()

            let preloadURLs = Array(nextPosts.prefix(2)).map(\.videoURL)
            bufferManager.preload(urls: preloadURLs, mode: .nearby)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var shouldFetchMoreCatalog: Bool {
        catalogPosts.isEmpty || (totalCount > 0 && catalogPosts.count < totalCount)
    }

    private func appendToCatalog(_ posts: [ShortsPost]) {
        guard !posts.isEmpty else { return }

        var existingIDs = Set(catalogPosts.map(\.id))
        let uniquePosts = posts.filter { existingIDs.insert($0.id).inserted }
        catalogPosts.append(contentsOf: uniquePosts)
    }

    private func nextCircularPosts(count: Int) -> [ShortsPost] {
        guard !catalogPosts.isEmpty else { return [] }

        let startIndex = visiblePosts.count % catalogPosts.count
        var nextPosts = (0..<min(count, catalogPosts.count)).map { offset in
            catalogPosts[(startIndex + offset) % catalogPosts.count]
        }

        if
            nextPosts.count > 1,
            let previousID = visiblePosts.last?.id,
            nextPosts.first?.id == previousID
        {
            nextPosts.append(nextPosts.removeFirst())
        }

        if catalogPosts.count == 1, visiblePosts.last?.id == nextPosts.first?.id {
            return []
        }

        return nextPosts
    }

    private func refreshSessionState() async {
        let favoriteIDs = await DemoSessionStore.shared.favoriteIDs()
        favoritePostIDs = Set(visiblePosts.compactMap { post in
            guard favoriteIDs.contains(post.sourceItem?.id ?? post.id) else { return nil }
            return post.id
        })

        var likedIDs = Set<ShortsPost.ID>()
        for post in visiblePosts {
            let itemID = post.sourceItem?.id ?? post.id
            if await DemoSessionStore.shared.likeState(for: itemID) == .liked {
                likedIDs.insert(post.id)
            }
        }
        likedPostIDs = likedIDs
    }
}

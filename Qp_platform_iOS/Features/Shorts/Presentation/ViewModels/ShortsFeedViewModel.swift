import Combine
import Foundation

@MainActor
final class ShortsFeedViewModel: ObservableObject {
    @Published private(set) var visiblePosts: [ShortsPost] = []
    @Published var currentPostID: ShortsPost.ID?
    @Published private(set) var isMuted = true
    @Published private(set) var likedPostIDs: Set<ShortsPost.ID> = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoadingInitial = false

    private let useCase: GetShortsBatchUseCase
    private let bufferManager: ShortsVideoBufferManager
    private let batchSize = 10
    private let fullBufferTriggerIndex = 5

    private var totalCount = 0
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

        let startupURLs = Array(visiblePosts.prefix(3)).map(\.videoURL)
        bufferManager.preload(urls: startupURLs, mode: .nearby)
    }

    func reload() async {
        visiblePosts = []
        currentPostID = nil
        likedPostIDs = []
        errorMessage = nil
        isLoadingInitial = false
        totalCount = 0
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
        if likedPostIDs.contains(postID) {
            likedPostIDs.remove(postID)
        } else {
            likedPostIDs.insert(postID)
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
        guard !isLoadingBatch, visiblePosts.count < max(totalCount, 1) || totalCount == 0 else { return }
        isLoadingBatch = true
        defer { isLoadingBatch = false }

        do {
            let batch = try await useCase.execute(offset: visiblePosts.count, limit: batchSize)
            totalCount = batch.totalCount
            catalogVideoURLs = batch.allVideoURLs
            errorMessage = nil

            guard !batch.posts.isEmpty else { return }
            visiblePosts.append(contentsOf: batch.posts)

            let preloadURLs = Array(batch.posts.prefix(2)).map(\.videoURL)
            bufferManager.preload(urls: preloadURLs, mode: .nearby)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

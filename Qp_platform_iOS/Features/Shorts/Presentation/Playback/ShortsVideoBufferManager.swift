import Foundation

final class ShortsVideoBufferManager {
    enum BufferMode {
        case nearby
        case fullFeed
    }

    static let shared = ShortsVideoBufferManager()

    private let fileManager = FileManager.default
    private let state = BufferState()

    // HLS (.m3u8) is a manifest of segments — it can't be file-cached like a progressive
    // mp4 (downloading the manifest alone yields unresolvable relative segment URLs).
    // Stream it directly; only progressive files go through the local cache.
    private func isStreamingManifest(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "m3u8"
    }

    func playbackURL(for remoteURL: URL) -> URL {
        guard !isStreamingManifest(remoteURL) else { return remoteURL }
        let localURL = cacheFileURL(for: remoteURL)
        return fileManager.fileExists(atPath: localURL.path) ? localURL : remoteURL
    }

    func preload(urls: [URL], mode: BufferMode) {
        Task(priority: .utility) { [weak self] in
            guard let self else { return }

            if mode == .fullFeed {
                await state.markFullFeedBufferStarted()
            }

            for remoteURL in urls where !isStreamingManifest(remoteURL) {
                await enqueueDownloadIfNeeded(for: remoteURL)
            }
        }
    }

    func shouldStartFullFeedBuffering() async -> Bool {
        await state.shouldStartFullFeedBuffering()
    }

    private func enqueueDownloadIfNeeded(for remoteURL: URL) async {
        let localURL = cacheFileURL(for: remoteURL)
        if fileManager.fileExists(atPath: localURL.path) {
            await state.markCached(remoteURL)
            return
        }

        let shouldStartDownload = await state.beginDownloadIfNeeded(for: remoteURL)
        guard shouldStartDownload else { return }

        Task(priority: .utility) { [weak self] in
            guard let self else { return }
            let downloadedURL = await downloadVideoIfNeeded(from: remoteURL)

            await state.completeDownload(
                for: remoteURL,
                didCacheFile: downloadedURL != nil
            )
        }
    }

    private actor BufferState {
        private var cachedRemoteURLs: Set<URL> = []
        private var inFlightDownloads: Set<URL> = []
        private var didStartFullFeedBuffer = false

        func markFullFeedBufferStarted() {
            didStartFullFeedBuffer = true
        }

        func shouldStartFullFeedBuffering() -> Bool {
            !didStartFullFeedBuffer
        }

        func beginDownloadIfNeeded(for remoteURL: URL) -> Bool {
            guard !cachedRemoteURLs.contains(remoteURL) else { return false }
            guard !inFlightDownloads.contains(remoteURL) else { return false }

            inFlightDownloads.insert(remoteURL)
            return true
        }

        func completeDownload(for remoteURL: URL, didCacheFile: Bool) {
            inFlightDownloads.remove(remoteURL)

            if didCacheFile {
                cachedRemoteURLs.insert(remoteURL)
            }
        }

        func markCached(_ remoteURL: URL) {
            cachedRemoteURLs.insert(remoteURL)
        }
    }

    private func downloadVideoIfNeeded(from remoteURL: URL) async -> URL? {
        let localURL = cacheFileURL(for: remoteURL)
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        do {
            try fileManager.createDirectory(
                at: cacheDirectoryURL(),
                withIntermediateDirectories: true
            )

            let (temporaryURL, _) = try await URLSession.shared.download(from: remoteURL)

            if fileManager.fileExists(atPath: localURL.path) {
                try? fileManager.removeItem(at: temporaryURL)
                return localURL
            }

            try fileManager.moveItem(at: temporaryURL, to: localURL)
            return localURL
        } catch {
            return nil
        }
    }

    private func cacheDirectoryURL() -> URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QPShortsVideoCache", isDirectory: true)
    }

    private func cacheFileURL(for remoteURL: URL) -> URL {
        let safeName = remoteURL.absoluteString
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "=", with: "_")

        let fileExtension = remoteURL.pathExtension.isEmpty ? "mp4" : remoteURL.pathExtension
        return cacheDirectoryURL().appendingPathComponent("\(safeName).\(fileExtension)")
    }
}

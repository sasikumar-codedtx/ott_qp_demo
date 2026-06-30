import Combine
import Foundation
import UIKit
import os

struct VideoVariant: Identifiable, Equatable {
    let id: Int          // maxHeight as key; 0 = Auto
    let displayName: String
    let maxHeight: Int   // 0 = unconstrained
    let maxBitrate: Double
}

#if canImport(FLPlatformPlayer) && canImport(FLPlayerInterface) && canImport(FLHeartbeat) && canImport(FLBookmarks)
import AVFoundation
import FLBookmarks
import FLContentAuthorizer
import FLFoundation
import FLHeartbeat
import FLPlatformCore
import FLPlatformPlayer
import FLPlayerInterface

@MainActor
final class QuickplayPlayerEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var isBuffering = true
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isReady = false
    @Published var isFinished = false
    @Published var error: QuickplayPlayerError?
    @Published var playerView: UIView?
    @Published var isMuted = false
    @Published private(set) var loadedContentId: String?
    @Published var isFullscreenSurfaceActive: Bool = false
    @Published var preferredVideoMaxHeight: Int = 0
    @Published private(set) var seekGeneration: Int = 0   // bumps on every user-initiated seek

    private var flPlayer: (any FLPlayerInterface.Player)?
    private var heartbeatManager: (any QuickplayHeartbeatManagerBox)?
    private var bookmarksManager: (any QuickplayBookmarksManagerBox)?
    #if !targetEnvironment(simulator)
    private var fairplayLicenseFetcher: (any FLPlayerInterface.FairplayLicenseFetcher)?
    #endif
    private var progressTimer: Timer?
    private var thumbnailGenerator: AVAssetImageGenerator?
    private var thumbnailCache: [Int: UIImage] = [:]
    private var memoryWarningObserver: NSObjectProtocol?
    private let injectedConfig: QuickplayPlayerConfig?

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ott.qp",
        category: "PlayerMemory"
    )

    // Proactive cap — 224×126px UIImage ≈ 110 KB each; 40 entries ≈ 4.4 MB
    private let thumbnailCacheLimit = 40

    init(config: QuickplayPlayerConfig? = nil) {
        self.injectedConfig = config
        subscribeToMemoryWarnings()
    }

    private func subscribeToMemoryWarnings() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleMemoryWarning()
            }
        }
    }

    private func handleMemoryWarning() {
        let evicted = thumbnailCache.count
        thumbnailCache.removeAll()
        thumbnailGenerator?.cancelAllCGImageGeneration()

        Self.logger.warning("""
            ⚠️ Memory warning received \
            | evicted \(evicted) thumbnails \
            | isReady=\(self.isReady) \
            | isBuffering=\(self.isBuffering) \
            | currentTime=\(String(format: "%.1f", self.currentTime))s \
            | duration=\(String(format: "%.1f", self.duration))s
            """)
    }

    func load(content: QuickplayPlaybackContent) async {
        loadedContentId = nil
        error = nil
        isFinished = false
        do {
            let runtimeConfig = await QuickplayConfigurationStore.shared.current()
            let config = injectedConfig ?? QuickplayPlayerConfig(config: runtimeConfig)
            try await QuickplayAuthRegistry.shared.enroll(config: config)
            let asset = try await QuickplayAuthRegistry.shared.authorizeContent(content: content)

            await buildPlayer(asset: asset, content: content, config: config)
            if error == nil { loadedContentId = content.contentId }
        } catch let quickplayError as QuickplayPlayerError {
            error = quickplayError
            isBuffering = false
        } catch {
            self.error = .playbackFailed(error.localizedDescription)
            isBuffering = false
        }
    }

    private func buildPlayer(
        asset: any FLContentAuthorizer.PlaybackAsset,
        content: QuickplayPlaybackContent,
        config: QuickplayPlayerConfig
    ) async {
        guard let url = URL(string: asset.contentUrl) else {
            error = .playbackFailed("Invalid content URL")
            isBuffering = false
            return
        }

        let t0 = CFAbsoluteTimeGetCurrent()
        Self.logger.debug("[Launch] buildPlayer start")

        // CDN origin servers require the QPAT in headers for authenticated access.
        let cdnHeaders: [String: String] = [
            "X-Authorization": config.defaultQpat,
            "X-Client-Id": config.xClientId
        ]
        let avAsset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": cdnHeaders])

        // AVAssetImageGenerator is created lazily in thumbnailImage(at:) — no allocation until first scrub.

        #if !targetEnvironment(simulator)
        // Cert fetch runs on a background thread while the player is constructed below.
        // By the time player + observer setup finishes, the cert is almost always ready.
        async let certData = Self.fetchFairplayCert(urlString: asset.fpCertificateUrl)
        #endif

        let player = FLPlatformPlayerFactory.player(asset: avAsset)
        playerView = player.playbackView

        player.playbackState.add(self) { [weak self] _, newState in
            let callbackT = CFAbsoluteTimeGetCurrent()
            let elapsed = Int((callbackT - t0) * 1000)
            let onMain = Thread.isMainThread
            Task { @MainActor in
                let lag = Int((CFAbsoluteTimeGetCurrent() - callbackT) * 1000)
                Self.logger.debug("[Launch] state=\(String(describing: newState)) thread=\(onMain ? "main" : "bg") elapsed=\(elapsed)ms taskLag=\(lag)ms")
                guard let self else { return }
                switch newState {
                case .playing:
                    self.isPlaying = true
                    self.isBuffering = false
                    self.isReady = true
                case .paused:
                    self.isPlaying = false
                case .loading:
                    self.isBuffering = true
                case .loaded:
                    self.isBuffering = false  // manifest ready, but DRM/frames may not be — isReady stays false
                case .idle:
                    break
                case .stopping:
                    self.isPlaying = false
                    self.isBuffering = false
                @unknown default:
                    self.isBuffering = false
                }
            }
        }

        player.isBuffering.add(self) { [weak self] _, buffering in
            Task { @MainActor in
                self?.isBuffering = buffering
            }
        }

        // Timer is scheduled on RunLoop.main (we're @MainActor here), so it fires on the main thread.
        // assumeIsolated avoids Task queuing — prevents multiple currentTime updates per SwiftUI frame.
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self, weak player] _ in
            guard let player else { return }
            MainActor.assumeIsolated { [weak self] in
                guard let self else { return }
                self.currentTime = player.currentTime
                self.duration = player.duration
                if self.isReady && !self.isFinished && self.duration > 0 && self.currentTime >= self.duration - 0.5 {
                    self.isFinished = true
                    self.isPlaying = false
                }
            }
        }

        if content.resumePosition > 0 {
            player.seek(to: content.resumePosition)
        }

        flPlayer = player

        #if !targetEnvironment(simulator)
        // Await cert — ran in parallel with player setup so latency is overlapped.
        // Must be registered before play() so no FairPlay key request is missed.
        setupFairPlay(asset: asset, avAsset: avAsset, certData: await certData)
        Self.logger.debug("[Launch] fairplay ready — +\(Int((CFAbsoluteTimeGetCurrent() - t0) * 1000))ms")
        #endif

        // SDK requires heartbeat and bookmark blocks to be registered BEFORE play().
        // Initialization cost here is absorbed by the loading phase (spinner visible).
        let hbT = CFAbsoluteTimeGetCurrent()
        startHeartbeat(asset: asset, content: content, config: config, player: player)
        Self.logger.debug("[Launch] heartbeat ready — \(Int((CFAbsoluteTimeGetCurrent() - hbT) * 1000))ms (total +\(Int((CFAbsoluteTimeGetCurrent() - t0) * 1000))ms)")

        let bmT = CFAbsoluteTimeGetCurrent()
        startBookmarks(content: content, config: config, player: player)
        Self.logger.debug("[Launch] bookmarks ready — \(Int((CFAbsoluteTimeGetCurrent() - bmT) * 1000))ms (total +\(Int((CFAbsoluteTimeGetCurrent() - t0) * 1000))ms)")

        Self.logger.debug("[Launch] calling play() — total +\(Int((CFAbsoluteTimeGetCurrent() - t0) * 1000))ms")
        player.play()
        isPlaying = true
        Self.logger.debug("[Launch] play() returned — total +\(Int((CFAbsoluteTimeGetCurrent() - t0) * 1000))ms")
    }

    #if !targetEnvironment(simulator)
    private func setupFairPlay(
        asset: any FLContentAuthorizer.PlaybackAsset,
        avAsset: AVURLAsset,
        certData: Data
    ) {
        guard asset.drm == .fairplay else { return }
        guard let licenseURLString = asset.licenseUrl, let licenseURL = URL(string: licenseURLString) else { return }
        guard let authorizer = QuickplayAuthRegistry.shared.platformAuthorizer else { return }

        let skd = asset.skd ?? ""
        let fetcher = FLPlatformPlayerFactory.fairplaylicenseFetcher()
        let fetcherDelegate = FLPlatformPlayerFactory.fairplayLicenseFetcherDelegate(
            applicationCertificate: certData,
            licenseUrl: licenseURL,
            skd: skd,
            keyDeliveryType: .streamingKey,
            platformAuthorizer: authorizer
        )
        fetcher.updateLicenseFetcherDelegate(fetcherDelegate, for: avAsset)
        fairplayLicenseFetcher = fetcher
    }

    private nonisolated static func fetchFairplayCert(urlString: String?) async -> Data {
        guard let urlString, let url = URL(string: urlString) else { return Data() }
        // returnCacheDataElseLoad: use URLSession disk cache regardless of expiry.
        // FairPlay app certificates are long-lived — stale cache is always valid.
        // After first fetch this returns instantly on every subsequent app launch.
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              !data.isEmpty else { return Data() }
        return data
    }
    #endif

    private func startHeartbeat(
        asset: any FLContentAuthorizer.PlaybackAsset,
        content: QuickplayPlaybackContent,
        config: QuickplayPlayerConfig,
        player: any FLPlayerInterface.Player
    ) {
        guard let heartbeatToken = asset.heartbeatToken,
              asset.heartbeatFlag == true,
              let authorizer = QuickplayAuthRegistry.shared.platformAuthorizer,
              let device = QuickplayAuthRegistry.shared.platformClient else { return }

        let heartbeatConfig = FLHeartbeatFactory.heartbeatConfiguration(
            heartbeatEndPointUrl: config.heartbeatEndpoint,
            streamConcurrencyEndPointUrl: config.streamConcurrencyEndpoint,
            syncInterval: config.heartBeatSyncIntervalMs
        )
        let heartbeatService = FLHeartbeatFactory.heartbeatService(
            contentId: content.contentId,
            deviceId: device.id,
            endPoint: config.heartbeatEndpoint,
            authorizer: authorizer
        )
        let monitoredHeartbeatService = QuickplayMonitoredHeartbeatService(service: heartbeatService) { [weak self] message in
            Task { @MainActor [weak self] in
                self?.isBuffering = false
                self?.error = .playbackFailed(message)
            }
        }

        let manager = FLHeartbeatFactory.heartbeatManager(
            configuration: heartbeatConfig,
            deviceId: device.id,
            contentId: content.contentId,
            heartbeatToken: heartbeatToken,
            authorizer: authorizer,
            heartbeatService: monitoredHeartbeatService
        )

        let wrapper = QuickplayHeartbeatWrapper(manager: manager)
        player.addHeartBeatBlock { [weak wrapper] player in
            let t = CFAbsoluteTimeGetCurrent()
            let onMain = Thread.isMainThread
            wrapper?.manager.processPlaybackProgress(player: player)
            let ms = Int((CFAbsoluteTimeGetCurrent() - t) * 1000)
            Self.logger.debug("[HB] heartbeat block thread=\(onMain ? "main" : "bg") took=\(ms)ms")
        }
        player.addStateChangeBlock { [weak wrapper] player in
            let t = CFAbsoluteTimeGetCurrent()
            wrapper?.manager.processPlaybackStateChange(player: player)
            let ms = Int((CFAbsoluteTimeGetCurrent() - t) * 1000)
            Self.logger.debug("[HB] heartbeat stateChange took=\(ms)ms")
        }
        heartbeatManager = wrapper
    }

    private func startBookmarks(
        content: QuickplayPlaybackContent,
        config: QuickplayPlayerConfig,
        player: any FLPlayerInterface.Player
    ) {
        guard let authorizer = QuickplayAuthRegistry.shared.platformAuthorizer else {
            print("[Bookmarks] skipped — no platform authorizer")
            return
        }

        let endPoint = config.bookmarkURL
        guard !endPoint.isEmpty else {
            print("[Bookmarks] skipped — bookmarkURL is empty (check remote config 'bookmarkURL')")
            return
        }

        print("[Bookmarks] starting — endPoint=\(endPoint) syncInterval=\(config.bookmarkSyncIntervalMs)ms contentId=\(content.contentId)")

        let bookmarkConfig = FLBookmarksFactory.bookmarkSessionConfiguration(
            endPoint: endPoint,
            bookmarkSyncInterval: config.bookmarkSyncIntervalMs
        )
        let attributes = BookmarkAttributes(
            itemId: content.contentId,
            seasonId: content.seasonId,
            episodeId: content.contentType == .episode ? content.contentId : nil,
            contentType: content.rawContentType
        )
        let manager = FLBookmarksFactory.bookmarksManager(
            configuration: bookmarkConfig,
            bookmarkAttributes: attributes,
            authorizer: authorizer
        )

        let wrapper = QuickplayBookmarksWrapper(manager: manager)
        // addHeartBeatBlock drives the configured bookmarkSyncInterval — SDK uses this to pace saves.
        // addStateChangeBlock (save on pause/stop) intentionally omitted.
        player.addHeartBeatBlock { [weak wrapper] player in
            let t = CFAbsoluteTimeGetCurrent()
            let onMain = Thread.isMainThread
            wrapper?.manager.processPlaybackProgress(player: player)
            let ms = Int((CFAbsoluteTimeGetCurrent() - t) * 1000)
            Self.logger.debug("[BM] bookmark block thread=\(onMain ? "main" : "bg") took=\(ms)ms")
        }
        bookmarksManager = wrapper
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func play() {
        flPlayer?.play()
        isPlaying = true
    }

    func pause() {
        flPlayer?.pause()
        isPlaying = false
    }

    func seek(to seconds: Double) {
        flPlayer?.seek(to: seconds)
        seekGeneration &+= 1
    }

    func setPreferredBitrate(_ bitrate: Double) {
        flPlayer?.avURLAsset?.resourceLoader.preloadsEligibleContentKeys = true
    }

    func setPlaybackRate(_ rate: Float) {
        flPlayer?.rate = rate
    }

    func toggleMute() {
        guard let flPlayer else { return }
        flPlayer.isMuted.toggle()
        isMuted = flPlayer.isMuted
    }

    func thumbnailImage(at seconds: Double) async -> UIImage? {
        if thumbnailGenerator == nil, let avAsset = flPlayer?.avURLAsset {
            let gen = AVAssetImageGenerator(asset: avAsset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: 224, height: 126)
            gen.requestedTimeToleranceBefore = CMTime(seconds: 2, preferredTimescale: 600)
            gen.requestedTimeToleranceAfter = CMTime(seconds: 2, preferredTimescale: 600)
            thumbnailGenerator = gen
        }
        guard let generator = thumbnailGenerator else { return nil }
        let bucket = Int(seconds / 10) * 10
        if let cached = thumbnailCache[bucket] { return cached }

        // Evict the oldest quarter of entries before the cache exceeds the cap
        if thumbnailCache.count >= thumbnailCacheLimit {
            let evictCount = thumbnailCacheLimit / 4
            thumbnailCache.keys.sorted().prefix(evictCount).forEach { thumbnailCache.removeValue(forKey: $0) }
            Self.logger.info("Thumbnail cache eviction — removed \(evictCount) oldest entries (cap: \(self.thumbnailCacheLimit))")
        }

        let image = await withCheckedContinuation { (cont: CheckedContinuation<UIImage?, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let time = CMTime(seconds: Double(bucket), preferredTimescale: 600)
                let img = (try? generator.copyCGImage(at: time, actualTime: nil)).map { UIImage(cgImage: $0) }
                cont.resume(returning: img)
            }
        }
        thumbnailCache[bucket] = image
        return image
    }

    var audioTracks: [MediaTrack] {
        flPlayer?.tracks(for: .audio) ?? []
    }

    var subtitleTracks: [MediaTrack] {
        (flPlayer?.tracks(for: .closedCaption) ?? []) + (flPlayer?.tracks(for: .subtitle) ?? [])
    }

    func selectAudioTrack(_ track: MediaTrack) {
        flPlayer?.selectTrack(track, for: .audio)
    }

    func selectSubtitleTrack(_ track: MediaTrack?) {
        flPlayer?.selectTrack(track, for: .subtitle)
        flPlayer?.selectTrack(track, for: .closedCaption)
    }

    func selectedAudioTrack() -> MediaTrack? {
        flPlayer?.selectedTrack(for: .audio)
    }

    func selectedSubtitleTrack() -> MediaTrack? {
        flPlayer?.selectedTrack(for: .subtitle) ?? flPlayer?.selectedTrack(for: .closedCaption)
    }

    func fetchVideoVariants() async -> [VideoVariant] {
        let auto = VideoVariant(id: 0, displayName: "Auto", maxHeight: 0, maxBitrate: 0)
        guard #available(iOS 15.0, *), let flPlayer else { return [auto] }
        return await withCheckedContinuation { cont in
            flPlayer.getAllVariantTracks { variants in
                let videoData = (variants ?? []).compactMap { v -> (height: Int, bitrate: Double)? in
                    guard let attr = v.videoAttributes,
                          attr.presentationSize.height > 0 else { return nil }
                    let bitrate = v.peakBitRate ?? v.averageBitRate ?? 0
                    return (Int(attr.presentationSize.height), bitrate)
                }
                guard !videoData.isEmpty else { cont.resume(returning: [auto]); return }

                let buckets: [(String, Int, Int)] = [
                    ("SD", 480, 1),
                    ("HD", 720, 481),
                    ("Full HD", 1080, 721),
                    ("4K UHD", 2160, 1081)
                ]
                var result: [VideoVariant] = [auto]
                for (label, maxH, minH) in buckets {
                    let inBucket = videoData.filter { $0.height >= minH && $0.height <= maxH }
                    if let best = inBucket.max(by: { $0.bitrate < $1.bitrate }) {
                        result.append(VideoVariant(id: maxH, displayName: label, maxHeight: maxH, maxBitrate: best.bitrate))
                    }
                }
                cont.resume(returning: result)
            }
        }
    }

    func setVideoQuality(_ variant: VideoVariant) {
        preferredVideoMaxHeight = variant.maxHeight
        let size = variant.maxHeight > 0 ? CGSize(width: 0, height: CGFloat(variant.maxHeight)) : .zero
        flPlayer?.set(preferences: [
            .preferredMaximumResolution(size: size),
            .preferredPeakBitRate(bitrate: variant.maxBitrate)
        ])
    }

    func release() {
        progressTimer?.invalidate()
        progressTimer = nil
        flPlayer?.playbackState.remove(self)
        flPlayer?.isBuffering.remove(self)
        // Final bookmark save — fire-and-forget before the player stops
        if let player = flPlayer { bookmarksManager?.saveBookmarkNow(player: player) }
        flPlayer?.stop()
        flPlayer = nil
        heartbeatManager = nil
        bookmarksManager = nil
        #if !targetEnvironment(simulator)
        fairplayLicenseFetcher = nil
        #endif
        thumbnailGenerator?.cancelAllCGImageGeneration()
        thumbnailGenerator = nil
        thumbnailCache.removeAll()
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
            memoryWarningObserver = nil
        }
        playerView = nil
        isMuted = false
        isReady = false
        isFinished = false
        isPlaying = false
        isBuffering = true
        error = nil
        loadedContentId = nil
        // isFullscreenSurfaceActive is intentionally NOT reset here.
        // QuickplayPlayerScreen.onDisappear is the sole owner of this flag.
        // Resetting it here would cause episode switches within an active
        // fullscreen session to route the new playerView to the inline surface.
        preferredVideoMaxHeight = 0
    }
}

private protocol QuickplayHeartbeatManagerBox: AnyObject {}
private protocol QuickplayBookmarksManagerBox: AnyObject {
    func saveBookmarkNow(player: any FLPlayerInterface.Player)
}

private final class QuickplayHeartbeatWrapper: QuickplayHeartbeatManagerBox {
    let manager: any FLHeartbeat.HeartbeatManager
    init(manager: any FLHeartbeat.HeartbeatManager) {
        self.manager = manager
    }
}

private final class QuickplayMonitoredHeartbeatService: FLHeartbeat.HeartbeatService {
    let contentId: String
    let deviceId: String

    private let service: any FLHeartbeat.HeartbeatService
    private let onFailure: (String) -> Void

    init(service: any FLHeartbeat.HeartbeatService, onFailure: @escaping (String) -> Void) {
        self.service = service
        self.contentId = service.contentId
        self.deviceId = service.deviceId
        self.onFailure = onFailure
    }

    func heartbeat(
        token: String,
        offset: TimeInterval?,
        primaryId: String?,
        catalogType: String?,
        headers: FLFoundation.Headers?,
        completion: @escaping (Result<(any FLHeartbeat.HeartbeatResponse)?, any Error>) -> Void
    ) {
        service.heartbeat(
            token: token,
            offset: offset,
            primaryId: primaryId,
            catalogType: catalogType,
            headers: headers
        ) { [onFailure] result in
            switch result {
            case .success(let response):
                if let action = response?.heartbeatAction, action != .continueHeartbeat {
                    onFailure("Heartbeat action: \(action.rawValue)")
                }
            case .failure(let error):
                onFailure("Heartbeat failed: \(error.localizedDescription)")
            }
            completion(result)
        }
    }
}

private final class QuickplayBookmarksWrapper: QuickplayBookmarksManagerBox {
    let manager: any FLBookmarks.BookmarksManager
    init(manager: any FLBookmarks.BookmarksManager) {
        self.manager = manager
    }
    func saveBookmarkNow(player: any FLPlayerInterface.Player) {
        manager.processPlaybackProgress(player: player)
    }
}
#else
@MainActor
final class QuickplayPlayerEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isReady = false
    @Published var isFinished = false
    @Published var error: QuickplayPlayerError? = .sdkUnavailable
    @Published var playerView: UIView?
    @Published var isMuted = false

    func load(content: QuickplayPlaybackContent) async {
        error = .sdkUnavailable
    }

    @Published var preferredVideoMaxHeight: Int = 0
    @Published private(set) var seekGeneration: Int = 0
    var loadedContentId: String? { nil }
    var isFullscreenSurfaceActive: Bool = false

    func togglePlayPause() {}
    func play() {}
    func pause() {}
    func seek(to seconds: Double) { seekGeneration &+= 1 }
    func setPreferredBitrate(_ bitrate: Double) {}
    func setPlaybackRate(_ rate: Float) {}
    func toggleMute() { isMuted.toggle() }
    func thumbnailImage(at seconds: Double) async -> UIImage? { nil }
    func release() {}
    func fetchVideoVariants() async -> [VideoVariant] { [] }
    func setVideoQuality(_ variant: VideoVariant) {}
}
#endif

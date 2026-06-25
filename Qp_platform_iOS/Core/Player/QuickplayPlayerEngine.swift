import Combine
import Foundation
import UIKit

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
    @Published var error: QuickplayPlayerError?
    @Published var playerView: UIView?

    private var flPlayer: (any FLPlayerInterface.Player)?
    private var heartbeatManager: (any QuickplayHeartbeatManagerBox)?
    private var bookmarksManager: (any QuickplayBookmarksManagerBox)?
    #if !targetEnvironment(simulator)
    private var fairplayLicenseFetcher: (any FLPlayerInterface.FairplayLicenseFetcher)?
    #endif
    private var progressTimer: Timer?
    private var itemObserver: NSKeyValueObservation?
    private let injectedConfig: QuickplayPlayerConfig?

    init(config: QuickplayPlayerConfig? = nil) {
        self.injectedConfig = config
    }

    func load(content: QuickplayPlaybackContent) async {
        do {
            let runtimeConfig = await QuickplayConfigurationStore.shared.current()
            let config = injectedConfig ?? QuickplayPlayerConfig(config: runtimeConfig)
            try await QuickplayAuthRegistry.shared.enroll(config: config)
            let asset = try await QuickplayAuthRegistry.shared.authorizeContent(content: content)

            var fairplayCertificateData: Data?
            #if !targetEnvironment(simulator)
            if asset.drm == .fairplay, let certURLString = asset.fpCertificateUrl, let certURL = URL(string: certURLString) {
                let request = URLRequest(url: certURL)
                if let (data, _) = try? await URLSession.shared.data(for: request), !data.isEmpty {
                    fairplayCertificateData = data
                    print("[Player] cert ✅ \(data.count)b")
                } else {
                    print("[Player] cert ❌ fetch failed — \(certURLString)")
                }
            } else {
                print("[Player] cert ❌ drm=\(asset.drm) fpCertUrl=\(asset.fpCertificateUrl ?? "nil")")
            }
            #endif

            buildPlayer(asset: asset, content: content, config: config, fairplayCertificateData: fairplayCertificateData)
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
        config: QuickplayPlayerConfig,
        fairplayCertificateData: Data?
    ) {
        guard let url = URL(string: asset.contentUrl) else {
            error = .playbackFailed("Invalid content URL")
            isBuffering = false
            return
        }

        // CDN origin servers require the QPAT in headers for authenticated access.
        let cdnHeaders: [String: String] = [
            "X-Authorization": config.defaultQpat,
            "X-Client-Id": config.xClientId
        ]
        let avAsset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": cdnHeaders])

        #if !targetEnvironment(simulator)
        setupFairPlay(asset: asset, avAsset: avAsset, fairplayCertificateData: fairplayCertificateData)
        #endif

        let player = FLPlatformPlayerFactory.player(asset: avAsset)
        playerView = player.playbackView
        print("[Player] view=\(player.playbackView != nil ? "✅" : "❌nil") → play()")

        player.playbackState.add(self) { [weak self] _, newState in
            Task { @MainActor in
                guard let self else { return }
                print("[Player] playbackState → \(newState)")
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
                    self.isBuffering = false
                    self.isReady = true
                case .idle:
                    break
                case .stopping:
                    self.isPlaying = false
                    self.isBuffering = false
                @unknown default:
                    print("[Player] ⚠️ Unhandled state: \(newState) — clearing buffer")
                    self.isBuffering = false
                }
            }
        }

        player.isBuffering.add(self) { [weak self] _, buffering in
            Task { @MainActor in
                print("[Player] isBuffering → \(buffering)")
                self?.isBuffering = buffering
            }
        }

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self, weak player] _ in
            guard let player else { return }
            Task { @MainActor in
                self?.currentTime = player.currentTime
                self?.duration = player.duration
            }
        }

        if content.resumePosition > 0 {
            player.seek(to: content.resumePosition)
        }

        flPlayer = player
        player.play()
        isPlaying = true
        startHeartbeat(asset: asset, content: content, config: config)
        startBookmarks(content: content, config: config)
    }

    #if !targetEnvironment(simulator)
    private func setupFairPlay(
        asset: any FLContentAuthorizer.PlaybackAsset,
        avAsset: AVURLAsset,
        fairplayCertificateData: Data?
    ) {
        guard asset.drm == .fairplay else {
            print("[DRM] skip — drm=\(asset.drm)")
            return
        }
        guard let licenseURLString = asset.licenseUrl, let licenseURL = URL(string: licenseURLString) else {
            print("[DRM] ❌ licenseUrl nil")
            return
        }
        guard let authorizer = QuickplayAuthRegistry.shared.platformAuthorizer else {
            print("[DRM] ❌ authorizer nil")
            return
        }

        // SKD is extracted from the HLS manifest by AVFoundation during key exchange — not needed upfront.
        let skd = asset.skd ?? ""
        let certData = fairplayCertificateData ?? Data()

        if certData.isEmpty {
            print("[DRM] ⚠️ no cert — key exchange will likely fail")
        }

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
        print("[DRM] ✅ configured — cert=\(certData.count)b skd='\(skd.isEmpty ? "from-manifest" : skd)'")
    }
    #endif

    private func startHeartbeat(asset: any FLContentAuthorizer.PlaybackAsset, content: QuickplayPlaybackContent, config: QuickplayPlayerConfig) {
        guard let heartbeatToken = asset.heartbeatToken,
              asset.heartbeatFlag == true,
              let authorizer = QuickplayAuthRegistry.shared.platformAuthorizer,
              let device = QuickplayAuthRegistry.shared.platformClient,
              let player = flPlayer else { return }

        let heartbeatConfig = FLHeartbeatFactory.heartbeatConfiguration(
            heartbeatEndPointUrl: config.heartbeatEndpoint,
            streamConcurrencyEndPointUrl: config.streamConcurrencyEndpoint
        )
        let manager = FLHeartbeatFactory.heartbeatManager(
            configuration: heartbeatConfig,
            deviceId: device.id,
            contentId: content.contentId,
            heartbeatToken: heartbeatToken,
            authorizer: authorizer
        )

        let wrapper = QuickplayHeartbeatWrapper(manager: manager)
        player.addHeartBeatBlock { [weak wrapper] player in
            wrapper?.manager.processPlaybackProgress(player: player)
        }
        player.addStateChangeBlock { [weak wrapper] player in
            wrapper?.manager.processPlaybackStateChange(player: player)
        }
        heartbeatManager = wrapper
    }

    private func startBookmarks(content: QuickplayPlaybackContent, config: QuickplayPlayerConfig) {
        guard let authorizer = QuickplayAuthRegistry.shared.platformAuthorizer,
              let player = flPlayer else { return }

        let bookmarkConfig = FLBookmarksFactory.bookmarkSessionConfiguration(
            endPoint: config.contentAuthEndpoint
        )
        let attributes = BookmarkAttributes(
            itemId: content.contentId,
            seasonId: content.seasonId,
            episodeId: content.contentType == .episode ? content.contentId : nil,
            contentType: content.contentType.catalogType
        )
        let manager = FLBookmarksFactory.bookmarksManager(
            configuration: bookmarkConfig,
            bookmarkAttributes: attributes,
            authorizer: authorizer
        )

        let wrapper = QuickplayBookmarksWrapper(manager: manager)
        player.addStateChangeBlock { [weak wrapper] player in
            wrapper?.manager.processPlaybackStateChange(player: player)
        }
        player.addHeartBeatBlock { [weak wrapper] player in
            wrapper?.manager.processPlaybackProgress(player: player)
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
    }

    func setPreferredBitrate(_ bitrate: Double) {
        flPlayer?.avURLAsset?.resourceLoader.preloadsEligibleContentKeys = true
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
    }

    func selectedAudioTrack() -> MediaTrack? {
        flPlayer?.selectedTrack(for: .audio)
    }

    func selectedSubtitleTrack() -> MediaTrack? {
        flPlayer?.selectedTrack(for: .subtitle) ?? flPlayer?.selectedTrack(for: .closedCaption)
    }

    func release() {
        progressTimer?.invalidate()
        progressTimer = nil
        flPlayer?.playbackState.remove(self)
        flPlayer?.isBuffering.remove(self)
        flPlayer?.stop()
        flPlayer = nil
        heartbeatManager = nil
        bookmarksManager = nil
        #if !targetEnvironment(simulator)
        fairplayLicenseFetcher = nil
        #endif
        playerView = nil
        isReady = false
        isPlaying = false
        isBuffering = true
    }
}

private protocol QuickplayHeartbeatManagerBox: AnyObject {}
private protocol QuickplayBookmarksManagerBox: AnyObject {}

private final class QuickplayHeartbeatWrapper: QuickplayHeartbeatManagerBox {
    let manager: any FLHeartbeat.HeartbeatManager
    init(manager: any FLHeartbeat.HeartbeatManager) {
        self.manager = manager
    }
}

private final class QuickplayBookmarksWrapper: QuickplayBookmarksManagerBox {
    let manager: any FLBookmarks.BookmarksManager
    init(manager: any FLBookmarks.BookmarksManager) {
        self.manager = manager
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
    @Published var error: QuickplayPlayerError? = .sdkUnavailable
    @Published var playerView: UIView?

    func load(content: QuickplayPlaybackContent) async {
        error = .sdkUnavailable
    }

    func togglePlayPause() {}
    func play() {}
    func pause() {}
    func seek(to seconds: Double) {}
    func setPreferredBitrate(_ bitrate: Double) {}
    func release() {}
}
#endif

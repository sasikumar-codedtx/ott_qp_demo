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
    private let config: QuickplayPlayerConfig

    init(config: QuickplayPlayerConfig? = nil) {
        self.config = config ?? .current
    }

    func load(content: QuickplayPlaybackContent) async {
        do {
            try await QuickplayAuthRegistry.shared.enroll(config: config)
            let asset = try await QuickplayAuthRegistry.shared.authorizeContent(content: content)

            var fairplayCertificateData: Data?
            #if !targetEnvironment(simulator)
            if asset.drm == .fairplay,
               let certificateURLString = asset.fpCertificateUrl,
               let certificateURL = URL(string: certificateURLString) {
                fairplayCertificateData = try? await URLSession.shared.data(from: certificateURL).0
            }
            #endif

            buildPlayer(asset: asset, content: content, fairplayCertificateData: fairplayCertificateData)
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
        fairplayCertificateData: Data?
    ) {
        guard let url = URL(string: asset.contentUrl) else {
            error = .playbackFailed("Invalid content URL")
            isBuffering = false
            return
        }

        let avAsset = AVURLAsset(url: url)

        #if !targetEnvironment(simulator)
        if asset.drm == .fairplay,
           let licenseURLString = asset.licenseUrl,
           let licenseURL = URL(string: licenseURLString),
           let skd = asset.skd,
           let fairplayCertificateData,
           let authorizer = QuickplayAuthRegistry.shared.platformAuthorizer {
            let fetcher = FLPlatformPlayerFactory.fairplaylicenseFetcher()
            let fetcherDelegate = FLPlatformPlayerFactory.fairplayLicenseFetcherDelegate(
                applicationCertificate: fairplayCertificateData,
                licenseUrl: licenseURL,
                skd: skd,
                keyDeliveryType: .streamingKey,
                platformAuthorizer: authorizer
            )
            fetcher.updateLicenseFetcherDelegate(fetcherDelegate, for: avAsset)
            fairplayLicenseFetcher = fetcher
        }
        #endif

        let player = FLPlatformPlayerFactory.player(asset: avAsset)
        playerView = player.playbackView

        player.playbackState.add(self) { [weak self] _, newState in
            Task { @MainActor in
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
                    self.isBuffering = false
                    self.isReady = true
                case .idle, .stopping:
                    break
                @unknown default:
                    break
                }
            }
        }

        player.isBuffering.add(self) { [weak self] _, isBuffering in
            Task { @MainActor in
                self?.isBuffering = isBuffering
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
        startHeartbeat(asset: asset, content: content)
        startBookmarks(content: content)
    }

    private func startHeartbeat(asset: any FLContentAuthorizer.PlaybackAsset, content: QuickplayPlaybackContent) {
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

    private func startBookmarks(content: QuickplayPlaybackContent) {
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

import AVFoundation
import Combine
import Foundation

final class ShortsPlaybackController: ObservableObject {
    @Published private(set) var isLoading = true

    let player = AVPlayer()

    private let bufferManager: ShortsVideoBufferManager
    private var currentRemoteURL: URL?
    private var playbackObserver: NSObjectProtocol?
    private var itemStatusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?

    init(bufferManager: ShortsVideoBufferManager = .shared) {
        self.bufferManager = bufferManager

        player.actionAtItemEnd = .none
        player.automaticallyWaitsToMinimizeStalling = true

        observePlaybackState()
    }

    func prepare(remoteURL: URL) {
        let playbackURL = bufferManager.playbackURL(for: remoteURL)
        guard currentRemoteURL != remoteURL || player.currentItem == nil else { return }

        currentRemoteURL = remoteURL
        isLoading = true
        removeObservers()

        let item = AVPlayerItem(asset: AVURLAsset(url: playbackURL))
        item.preferredForwardBufferDuration = 4

        itemStatusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.isLoading = item.status != .readyToPlay
            }
        }

        playbackObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }

        player.replaceCurrentItem(with: item)
    }

    func setPlaying(_ isPlaying: Bool) {
        isPlaying ? player.play() : player.pause()
    }

    func setMuted(_ isMuted: Bool) {
        player.isMuted = isMuted
    }

    deinit {
        removeObservers()
        player.pause()
        player.replaceCurrentItem(with: nil)
    }

    private func observePlaybackState() {
        timeControlObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                switch player.timeControlStatus {
                case .playing:
                    self?.isLoading = false
                case .waitingToPlayAtSpecifiedRate:
                    self?.isLoading = true
                case .paused:
                    self?.isLoading = player.currentItem?.status != .readyToPlay
                @unknown default:
                    self?.isLoading = true
                }
            }
        }
    }

    private func removeObservers() {
        if let playbackObserver {
            NotificationCenter.default.removeObserver(playbackObserver)
            self.playbackObserver = nil
        }

        itemStatusObserver = nil
    }
}

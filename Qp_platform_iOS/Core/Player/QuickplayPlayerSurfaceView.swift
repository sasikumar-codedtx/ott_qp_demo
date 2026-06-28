import SwiftUI
import UIKit

struct QuickplayPlayerSurfaceView: UIViewRepresentable {
    @ObservedObject var engine: QuickplayPlayerEngine
    var isPrimary: Bool = false

    func makeUIView(context: Context) -> PlayerSurfaceContainer {
        let container = PlayerSurfaceContainer()
        container.backgroundColor = .black
        return container
    }

    func updateUIView(_ uiView: PlayerSurfaceContainer, context: Context) {
        let fsActive = engine.isFullscreenSurfaceActive
        let canClaim = isPrimary == fsActive

        guard let playbackView = engine.playerView else {
            uiView.subviews.forEach { $0.removeFromSuperview() }
            return
        }

        let alreadyOwned = playbackView.superview === uiView

        if !canClaim {
            if alreadyOwned {
                playbackView.removeFromSuperview()
            }
            return
        }

        guard !alreadyOwned else {
            playbackView.setNeedsLayout()
            playbackView.layoutIfNeeded()
            return
        }

        uiView.subviews.forEach { $0.removeFromSuperview() }
        playbackView.removeFromSuperview()
        playbackView.translatesAutoresizingMaskIntoConstraints = false
        uiView.addSubview(playbackView)
        NSLayoutConstraint.activate([
            playbackView.topAnchor.constraint(equalTo: uiView.topAnchor),
            playbackView.bottomAnchor.constraint(equalTo: uiView.bottomAnchor),
            playbackView.leadingAnchor.constraint(equalTo: uiView.leadingAnchor),
            playbackView.trailingAnchor.constraint(equalTo: uiView.trailingAnchor)
        ])
    }
}

// MARK: - Container

final class PlayerSurfaceContainer: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let playerView = subviews.first else { return }
        playerView.setNeedsLayout()
        playerView.layoutIfNeeded()
    }
}

import SwiftUI
import UIKit

struct QuickplayPlayerSurfaceView: UIViewRepresentable {
    @ObservedObject var engine: QuickplayPlayerEngine
    var isPrimary: Bool = false

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .black
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let playbackView = engine.playerView else {
            uiView.subviews.forEach { $0.removeFromSuperview() }
            return
        }

        // When fullscreen is active, only the primary (fullscreen) surface may hold the playerView.
        // The inline surface must release it to avoid pulling the layer back during layout passes.
        let canClaim = isPrimary || !engine.isFullscreenSurfaceActive

        if !canClaim {
            if playbackView.superview === uiView {
                playbackView.removeFromSuperview()
            }
            return
        }

        guard playbackView.superview !== uiView else { return }
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

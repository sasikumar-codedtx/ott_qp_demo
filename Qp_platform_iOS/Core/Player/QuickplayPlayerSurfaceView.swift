import SwiftUI
import UIKit

struct QuickplayPlayerSurfaceView: UIViewRepresentable {
    @ObservedObject var engine: QuickplayPlayerEngine

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

        guard playbackView.superview !== uiView else { return }
        uiView.subviews.forEach { $0.removeFromSuperview() }
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

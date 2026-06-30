import SwiftUI
import UIKit

struct DetailInlinePlayerView: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    let content: QuickplayPlaybackContent
    let posterURL: URL?
    // Total header height = safeAreaTop + navBarHeight + videoHeight.
    // Poster fills all of it (covers status bar + nav bar area).
    // Video/controls sit only in the bottom portion below the nav bar.
    let height: CGFloat
    let safeAreaTop: CGFloat
    let navBarHeight: CGFloat
    let onFullscreen: () -> Void
    @State private var isSeeking = false
    @State private var seekPosition: Double = 0
    @State private var showControls = false

    private var videoHeight: CGFloat { height - safeAreaTop - navBarHeight }

    var body: some View {
        ZStack(alignment: .top) {
            // Poster spans from absolute screen top through the full header height.
            // Fades out once the video surface is ready; reappears when finished.
            PosterImageView(
                url: posterURL,
                size: CGSize(width: UIScreen.main.bounds.width, height: height),
                cornerRadius: 0
            )
            .opacity(engine.isReady && !engine.isFinished ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: engine.isReady)
            .animation(.easeInOut(duration: 0.35), value: engine.isFinished)

            // Video and controls — only in the area below the nav bar.
            VStack(spacing: 0) {
                Color.clear.frame(height: safeAreaTop + navBarHeight)

                ZStack {
                    QuickplayPlayerSurfaceView(engine: engine)
                        .opacity(engine.isReady && !engine.isFinished ? 1 : 0)
                        .animation(.easeInOut(duration: 0.45), value: engine.isReady)
                        .animation(.easeInOut(duration: 0.35), value: engine.isFinished)
                        .allowsHitTesting(false)

                    if engine.isReady && !engine.isFinished {
                        LinearGradient(
                            colors: [.black.opacity(0.2), .clear, .black.opacity(0.66)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .allowsHitTesting(false)

                        controls
                            .transition(.opacity)
                    }

                    if engine.isFinished {
                        ZStack {
                            Button {
                                engine.isFinished = false
                                engine.seek(to: 0)
                                engine.play()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(Circle().fill(Color.black.opacity(0x3B / 255.0)))
                                        .overlay(Circle().stroke(Color.white.opacity(0x33 / 255.0), lineWidth: 1.21))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .buttonStyle(LiquidButtonPressStyle())
                        }
                        .transition(.opacity.animation(.easeInOut(duration: 0.35)))
                    }
                }
                .frame(height: videoHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard engine.isReady && !engine.isFinished else { return }
                    withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
                }
            }
        }
        .frame(height: height)
        .clipped()
        .task(id: content.id) {
            guard engine.loadedContentId != content.contentId else { return }
            engine.release()
            await engine.load(content: content)
        }
        .onChange(of: engine.isReady) { _, ready in
            if !ready { showControls = false }
        }
        .onChange(of: isSeeking) { _, seeking in
            if !seeking { engine.seek(to: seekPosition) }
        }
    }

    private var controls: some View {
        ZStack {
            // Play/pause — centered
            if showControls {
                Button(action: engine.togglePlayPause) {
                    Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
                        .frame(width: 52, height: 52)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: engine.isPlaying)
                .transition(.opacity)
            }

            // The timeline stays pinned to the video bottom; controls fade like play/pause.
            VStack(spacing: showControls ? 7 : 0) {
                Spacer()

                if showControls {
                    HStack {
                        PlayerChromeIconButton(
                            assetImage: engine.isMuted ? "volume-off" : "volume-high",
                            action: engine.toggleMute
                        )
                        Spacer()
                        PlayerChromeIconButton(systemImage: "arrow.up.left.and.arrow.down.right", action: onFullscreen)
                    }
                    .padding(.horizontal, 12)
                    .transition(.opacity)
                }

                DetailSeekBar(
                    currentTime: engine.currentTime,
                    duration: engine.duration,
                    isSeeking: $isSeeking,
                    seekPosition: $seekPosition
                )
                .frame(height: 14)
            }
            .animation(.easeInOut(duration: 0.2), value: showControls)
        }
    }
}

// MARK: - Seekbar

private struct DetailSeekBar: View {
    let currentTime: Double
    let duration: Double
    @Binding var isSeeking: Bool
    @Binding var seekPosition: Double

    @State private var lockedPosition: Double? = nil

    private var progress: Double {
        guard duration > 0 else { return 0 }
        let t: Double
        if isSeeking { t = seekPosition }
        else if let locked = lockedPosition { t = locked }
        else { t = currentTime }
        return min(max(t / duration, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let thumbR: CGFloat = 6
            let barHeight: CGFloat = isSeeking ? 4 : 2.5
            let filled = max(0, CGFloat(progress) * w)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: barHeight)
                    .animation(.easeInOut(duration: 0.18), value: isSeeking)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: filled, height: barHeight)
                    .animation(.easeInOut(duration: 0.18), value: isSeeking)

                Circle()
                    .fill(Color.white)
                    .frame(
                        width: isSeeking ? thumbR * 2.4 : thumbR * 2,
                        height: isSeeking ? thumbR * 2.4 : thumbR * 2
                    )
                    .offset(x: max(0, filled - (isSeeking ? thumbR * 1.2 : thumbR)))
                    .animation(.easeInOut(duration: 0.18), value: isSeeking)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle().size(CGSize(width: w, height: 44)))
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        guard duration > 0 else { return }
                        if !isSeeking {
                            let thumbX = filled
                            guard abs(value.startLocation.x - thumbX) < 28 else { return }
                            isSeeking = true
                        }
                        seekPosition = min(max(Double(value.location.x / w) * duration, 0), duration)
                    }
                    .onEnded { _ in
                        lockedPosition = seekPosition
                        isSeeking = false
                    }
            )
            .onChange(of: currentTime) { _, t in
                guard let locked = lockedPosition, abs(t - locked) < 3.0 else { return }
                lockedPosition = nil
            }
        }
        .frame(height: 14)
    }
}

// MARK: - Chrome icon button

private struct PlayerChromeIconButton: View {
    var systemImage: String? = nil
    var assetImage: String? = nil
    let action: () -> Void

    private let bg = Color(red: 0, green: 0, blue: 0, opacity: 0x3B / 255.0)

    var body: some View {
        Button(action: action) {
            Group {
                if let asset = assetImage {
                    Image(asset)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                } else if let sys = systemImage {
                    Image(systemName: sys)
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(bg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

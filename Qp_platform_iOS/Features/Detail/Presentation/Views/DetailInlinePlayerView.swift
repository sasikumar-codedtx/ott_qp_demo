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
            // Fades out once the video surface is ready.
            PosterImageView(
                url: posterURL,
                size: CGSize(width: UIScreen.main.bounds.width, height: height),
                cornerRadius: 0
            )
            .opacity(engine.isReady ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: engine.isReady)

            // Video and controls — only in the area below the nav bar.
            VStack(spacing: 0) {
                Color.clear.frame(height: safeAreaTop + navBarHeight)

                ZStack {
                    QuickplayPlayerSurfaceView(engine: engine)
                        .opacity(engine.isReady ? 1 : 0)
                        .animation(.easeInOut(duration: 0.45), value: engine.isReady)
                        .allowsHitTesting(false)

                    if engine.isReady && showControls {
                        LinearGradient(
                            colors: [.black.opacity(0.3), .clear, .black.opacity(0.55)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .allowsHitTesting(false)

                        controls
                            .transition(.opacity)
                    }

                    if engine.error != nil {
                        VStack {
                            Spacer()
                            DetailPlayerErrorToast()
                                .padding(.bottom, 64)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        .animation(.easeInOut(duration: 0.3), value: engine.error != nil)
                    }
                }
                .frame(height: videoHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard engine.isReady else { return }
                    withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
                }
            }
        }
        .frame(height: height)
        .clipped()
        .task(id: content.id) {
            engine.release()
            await engine.load(content: content)
        }
        .onChange(of: engine.isReady) { _, ready in
            if !ready { showControls = false }
        }
        .onChange(of: isSeeking) { _, seeking in
            if !seeking { engine.seek(to: seekPosition) }
        }
        .onChange(of: engine.error) { _, error in
            guard error != nil else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private var controls: some View {
        ZStack {
            // Play/pause — centered
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

            // Bottom: mute | fullscreen + seekbar
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    PlayerChromeIconButton(
                        systemImage: engine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                        action: engine.toggleMute
                    )
                    Spacer()
                    PlayerChromeIconButton(systemImage: "arrow.up.left.and.arrow.down.right", action: onFullscreen)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

                DetailSeekBar(
                    currentTime: engine.currentTime,
                    duration: engine.duration,
                    isSeeking: $isSeeking,
                    seekPosition: $seekPosition
                )
            }
        }
    }
}

// MARK: - Seekbar

private struct DetailSeekBar: View {
    let currentTime: Double
    let duration: Double
    @Binding var isSeeking: Bool
    @Binding var seekPosition: Double

    private var progress: Double {
        guard duration > 0 else { return 0 }
        let t = isSeeking ? seekPosition : currentTime
        return min(max(t / duration, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let thumbR: CGFloat = 6
            let filled = max(0, CGFloat(progress) * w)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: isSeeking ? 4 : 2)
                    .animation(.easeInOut(duration: 0.18), value: isSeeking)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: filled, height: isSeeking ? 4 : 2)
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
                    .onEnded { _ in isSeeking = false }
            )
        }
        .frame(height: 44)
    }
}

// MARK: - Chrome icon button

private struct PlayerChromeIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.black.opacity(0.34), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

// MARK: - Error toast

private struct DetailPlayerErrorToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text("Unable to load video")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(.black.opacity(0.82), in: Capsule())
        .overlay(Capsule().stroke(.red.opacity(0.55), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

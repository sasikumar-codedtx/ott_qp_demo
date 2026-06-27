import SwiftUI
import UIKit

struct QuickplayPlayerControlsOverlay: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    let title: String
    let subtitle: String?
    let contentType: QuickplayPlaybackContent.ContentType
    @Binding var isSeeking: Bool
    @Binding var seekPosition: Double
    @Binding var showQualityDialog: Bool
    @Binding var showSubtitleDialog: Bool
    @Binding var showSpeedSheet: Bool
    let safeTop: CGFloat
    let safeLeading: CGFloat
    let safeTrailing: CGFloat
    let safeBottom: CGFloat
    let onDismiss: () -> Void

    @State private var seekThumbnail: UIImage? = nil

    private var seekBucket: Int { Int(seekPosition / 10) }

    var body: some View {
        ZStack {
            gradients

            VStack(spacing: 0) {
                if !isSeeking { topBar }
                Spacer()
                if !isSeeking { centerControls }
                Spacer()
                bottomArea
            }

            if !isSeeking {
                VStack {
                    Spacer()
                    QuickplayBrightnessSlider()
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, safeLeading + 20)
                .padding(.vertical, 70)
            }
        }
        .onChange(of: isSeeking) { _, seeking in
            if !seeking { engine.seek(to: seekPosition) }
        }
        .task(id: isSeeking ? seekBucket : -1) {
            guard isSeeking else { seekThumbnail = nil; return }
            seekThumbnail = await engine.thumbnailImage(at: Double(seekBucket) * 10)
        }
    }

    // MARK: Gradients

    private var gradients: some View {
        VStack(spacing: 0) {
            if !isSeeking {
                LinearGradient(colors: [.black.opacity(0.75), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
            }
            Spacer()
            LinearGradient(colors: [.clear, .black.opacity(0.88)], startPoint: .top, endPoint: .bottom)
                .frame(height: isSeeking ? 130 : 200)
        }
        .ignoresSafeArea()
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            NavigationChromeButton(icon: AppIcons.Navigation.back, action: onDismiss)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.leading, safeLeading + 18)
        .padding(.trailing, safeTrailing + 16)
        .padding(.top, safeTop + 12)
    }

    // MARK: Center — skip ±15s + play/pause

    private var centerControls: some View {
        HStack(spacing: 52) {
            Button { engine.seek(to: max(0, engine.currentTime - 15)) } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(LiquidButtonPressStyle())

            PlayPauseMorphButton(isPlaying: engine.isPlaying, size: 72) {
                engine.togglePlayPause()
            }

            Button { engine.seek(to: min(engine.duration, engine.currentTime + 15)) } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(LiquidButtonPressStyle())
        }
    }

    // MARK: Bottom

    private var bottomArea: some View {
        VStack(spacing: 0) {
            // Thumbnail preview — only during seeking
            if isSeeking {
                seekingThumbnailArea
                    .transition(.opacity)
            }

            seekRow

            actionPills
                .padding(.bottom, safeBottom + 14)
                .opacity(isSeeking ? 0 : 1)
                .animation(.easeInOut(duration: 0.18), value: isSeeking)
        }
    }

    // Thumbnail card + time centered above thumb
    private var seekingThumbnailArea: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let thumbPad: CGFloat = 24 + 7 // horizontal padding + thumbR
            let trackW = w - 2 * thumbPad
            let fraction = engine.duration > 0 ? CGFloat(min(max(seekPosition / engine.duration, 0), 1)) : 0
            let thumbX = thumbPad + trackW * fraction

            let cardW: CGFloat = 112
            let clampedX = min(max(thumbX, cardW / 2 + 8), w - cardW / 2 - 8)

            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "1A1A1A"))
                    if let img = seekThumbnail {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else {
                        Image(systemName: "film")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .frame(width: cardW, height: 63)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.3), lineWidth: 1))

                Text(formatTime(seekPosition))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: cardW)
            .position(x: clampedX, y: proxy.size.height / 2)
        }
        .frame(height: 90)
        .padding(.horizontal, 0)
        .animation(.easeInOut(duration: 0.1), value: seekThumbnail != nil)
    }

    // Seek bar row with remaining time on right
    private var seekRow: some View {
        HStack(alignment: .center, spacing: 12) {
            QuickplaySeekBar(
                currentTime: engine.currentTime,
                duration: engine.duration,
                isSeeking: $isSeeking,
                seekPosition: $seekPosition,
                accentColor: .white
            )

            let remaining = engine.duration - (isSeeking ? seekPosition : engine.currentTime)
            Text("-\(formatTime(max(0, remaining)))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .frame(minWidth: 52, alignment: .trailing)
                .padding(.trailing, safeTrailing + 16)
        }
    }

    // MARK: Bottom action pills

    private var showsEpisodeOptions: Bool {
        switch contentType {
        case .episode, .series, .show: return true
        case .movie, .channel: return false
        }
    }

    private var actionPills: some View {
        HStack(spacing: 16) {
            actionItem(icon: "gauge.medium", label: "Speed") { showSpeedSheet = true }
            actionItem(icon: "video.badge.ellipsis", label: "Video Quality") { showQualityDialog = true }
            if showsEpisodeOptions {
                actionItem(icon: "list.bullet.rectangle", label: "Episodes") { }
            }
            actionItem(icon: "captions.bubble", label: "Audio & Subtitle") { showSubtitleDialog = true }
            if showsEpisodeOptions {
                actionItem(icon: "forward.end.fill", label: "Play Next") { }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }

    private func actionItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(Color.white.opacity(0.12), in: Capsule())
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let t = Int(seconds)
        let h = t / 3600, m = (t % 3600) / 60, s = t % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}

// MARK: - Seek bar (Canvas-based, no layout reflow)

private struct QuickplaySeekBar: View {
    let currentTime: Double
    let duration: Double
    @Binding var isSeeking: Bool
    @Binding var seekPosition: Double
    let accentColor: Color

    @State private var lockedPosition: Double? = nil
    @State private var trackWidth: CGFloat = 0

    private var displayFraction: CGFloat {
        guard duration > 0 else { return 0 }
        let base: Double
        if isSeeking { base = seekPosition }
        else if let locked = lockedPosition { base = locked }
        else { base = currentTime }
        return CGFloat(min(max(base / duration, 0), 1))
    }

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, cy = size.height / 2
            let thumbR: CGFloat = 10, trackH: CGFloat = 3
            let progressX = thumbR + (w - 2 * thumbR) * displayFraction

            var bg = Path()
            bg.addRoundedRect(in: CGRect(x: thumbR, y: cy - trackH/2, width: w - 2*thumbR, height: trackH),
                              cornerSize: CGSize(width: trackH/2, height: trackH/2))
            ctx.fill(bg, with: .color(.white.opacity(0.3)))

            if displayFraction > 0 {
                var prog = Path()
                prog.addRoundedRect(in: CGRect(x: thumbR, y: cy - trackH/2, width: max(0, progressX - thumbR), height: trackH),
                                    cornerSize: CGSize(width: trackH/2, height: trackH/2))
                ctx.fill(prog, with: .color(accentColor))
            }

            ctx.fill(Path(ellipseIn: CGRect(x: progressX - thumbR, y: cy - thumbR, width: thumbR*2, height: thumbR*2)),
                     with: .color(accentColor))
        }
        .frame(height: 28)
        .contentShape(Rectangle())
        .background(GeometryReader { proxy in
            Color.clear
                .onAppear { trackWidth = proxy.size.width }
                .onChange(of: proxy.size.width) { _, w in trackWidth = w }
        })
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard duration > 0, trackWidth > 0 else { return }

                    if !isSeeking {
                        let thumbR: CGFloat = 10
                        let frac = CGFloat((lockedPosition ?? currentTime) / duration)
                        let thumbX = thumbR + (trackWidth - 2 * thumbR) * min(max(frac, 0), 1)
                        guard abs(value.startLocation.x - thumbX) <= 32 else { return }
                        guard abs(value.translation.width) > 4 else { return }
                        lockedPosition = nil
                        isSeeking = true
                    }

                    seekPosition = min(max(value.location.x / trackWidth, 0), 1) * duration
                }
                .onEnded { _ in
                    guard isSeeking else { return }
                    lockedPosition = seekPosition
                    isSeeking = false
                }
        )
        .onChange(of: currentTime) { _, t in
            guard let locked = lockedPosition, abs(t - locked) < 3.0 else { return }
            lockedPosition = nil
        }
    }
}

// MARK: - Vertical brightness slider (left side, Netflix-style)

private struct QuickplayBrightnessSlider: View {
    @State private var brightness: CGFloat = UIScreen.main.brightness

    private let sliderH: CGFloat = 140
    private let trackW: CGFloat = 4
    private let thumbR: CGFloat = 7

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "sun.max")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            Canvas { ctx, size in
                let cx = size.width / 2
                let h = size.height
                let tR = thumbR
                let tW = trackW
                let thumbY = tR + (h - 2 * tR) * (1 - brightness)

                // Background track
                var bg = Path()
                bg.addRoundedRect(
                    in: CGRect(x: cx - tW/2, y: tR, width: tW, height: h - 2*tR),
                    cornerSize: CGSize(width: tW/2, height: tW/2)
                )
                ctx.fill(bg, with: .color(.white.opacity(0.25)))

                // Fill from thumb down to track bottom — larger fill = higher brightness
                let fillH = (h - tR) - thumbY
                if fillH > 0 {
                    var fill = Path()
                    fill.addRoundedRect(
                        in: CGRect(x: cx - tW/2, y: thumbY, width: tW, height: fillH),
                        cornerSize: CGSize(width: tW/2, height: tW/2)
                    )
                    ctx.fill(fill, with: .color(.white))
                }

                // Thumb
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx - tR, y: thumbY - tR, width: tR*2, height: tR*2)),
                    with: .color(.white)
                )
            }
            .frame(width: 36, height: sliderH)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = 1 - ((value.location.y - thumbR) / (sliderH - 2 * thumbR))
                        brightness = max(0.05, min(1, fraction))
                        UIScreen.main.brightness = brightness
                    }
            )
        }
        .onAppear {
            brightness = UIScreen.main.brightness
        }
    }
}

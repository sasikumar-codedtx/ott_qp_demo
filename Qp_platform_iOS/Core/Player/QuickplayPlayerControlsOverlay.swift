import SwiftUI

struct QuickplayPlayerControlsOverlay: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    let title: String
    @Binding var isSeeking: Bool
    @Binding var seekPosition: Double
    @Binding var showQualityDialog: Bool
    @Binding var showSubtitleDialog: Bool
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.black.opacity(0.72), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 130)

                Spacer()

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
            }
            .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                playPauseButton
                Spacer()
                bottomControls
            }
        }
        .onChange(of: isSeeking) { _, newValue in
            if !newValue {
                engine.seek(to: seekPosition)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button(action: onDismiss) {
                Image(systemName: AppIcons.Navigation.back)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
            }
            .buttonStyle(LiquidButtonPressStyle())

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }

    private var playPauseButton: some View {
        Button {
            engine.togglePlayPause()
        } label: {
            Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 68, weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))
                .frame(width: 108, height: 108)
                .contentShape(Circle())
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private var bottomControls: some View {
        VStack(spacing: 14) {
            QuickplaySeekBar(
                currentTime: engine.currentTime,
                duration: engine.duration,
                isSeeking: $isSeeking,
                seekPosition: $seekPosition,
                accentColor: Color(hex: "FF6D2E")
            )

            HStack {
                Text(formatTime(isSeeking ? seekPosition : engine.currentTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Text(formatTime(engine.duration))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .padding(.horizontal, 24)

            HStack(spacing: 12) {
                Spacer()
                QuickplayPillButton(label: "Quality") {
                    showQualityDialog = true
                }
                QuickplayPillButton(label: "Subtitles") {
                    showSubtitleDialog = true
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 26)
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct QuickplaySeekBar: View {
    let currentTime: Double
    let duration: Double
    @Binding var isSeeking: Bool
    @Binding var seekPosition: Double
    let accentColor: Color

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max((isSeeking ? seekPosition : currentTime) / duration, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let trackHeight: CGFloat = isSeeking ? 4 : 2
            let thumbRadius: CGFloat = isSeeking ? 10 : 6

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: trackHeight)

                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(accentColor)
                    .frame(width: max(0, width * progress), height: trackHeight)

                Circle()
                    .fill(accentColor)
                    .frame(width: thumbRadius * 2, height: thumbRadius * 2)
                    .overlay(Circle().stroke(Color.white, lineWidth: isSeeking ? 2 : 0))
                    .offset(x: max(0, width * progress - thumbRadius))
            }
            .frame(height: thumbRadius * 2)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard duration > 0 else { return }
                        isSeeking = true
                        let percentage = min(max(value.location.x / width, 0), 1)
                        seekPosition = percentage * duration
                    }
                    .onEnded { _ in
                        isSeeking = false
                    }
            )
        }
        .frame(height: 22)
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.15), value: isSeeking)
    }
}

private struct QuickplayPillButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 32)
                .background(Color.white.opacity(0.18), in: Capsule(style: .continuous))
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

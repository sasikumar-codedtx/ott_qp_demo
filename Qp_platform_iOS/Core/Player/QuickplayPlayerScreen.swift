import SwiftUI

struct QuickplayPlayerScreen: View {
    let content: QuickplayPlaybackContent
    let onDismiss: () -> Void

    @StateObject private var engine = QuickplayPlayerEngine()
    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?
    @State private var isSeeking = false
    @State private var seekPosition: Double = 0
    @State private var showQualityDialog = false
    @State private var showSubtitleDialog = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            QuickplayPlayerSurfaceView(engine: engine)
                .ignoresSafeArea()

            if engine.isBuffering && !isSeeking {
                QuickplayPlayerLoadingView()
            }

            if let error = engine.error {
                errorView(error)
            }

            if controlsVisible || isSeeking {
                QuickplayPlayerControlsOverlay(
                    engine: engine,
                    title: content.title,
                    isSeeking: $isSeeking,
                    seekPosition: $seekPosition,
                    showQualityDialog: $showQualityDialog,
                    showSubtitleDialog: $showSubtitleDialog,
                    onDismiss: onDismiss
                )
                .transition(.opacity)
            }

            if showQualityDialog {
                QuickplayQualityDialog(engine: engine, isPresented: $showQualityDialog)
                    .transition(.move(edge: .trailing))
            }

            #if canImport(FLPlayerInterface)
            if showSubtitleDialog {
                QuickplaySubtitleDialog(engine: engine, isPresented: $showSubtitleDialog)
                    .transition(.move(edge: .trailing))
            }
            #endif
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: controlsVisible)
        .animation(.easeInOut(duration: 0.2), value: showQualityDialog)
        .animation(.easeInOut(duration: 0.2), value: showSubtitleDialog)
        .task {
            await engine.load(content: content)
            scheduleHide()
        }
        .onDisappear {
            hideTask?.cancel()
            engine.release()
        }
        .onTapGesture {
            showControls()
        }
    }

    private func errorView(_ error: QuickplayPlayerError) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Color(hex: "FF8A00"))
            Text(error.localizedDescription)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Dismiss", action: onDismiss)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "FF8A00"))
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func showControls() {
        controlsVisible = true
        scheduleHide()
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled && !isSeeking {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        controlsVisible = false
                    }
                }
            }
        }
    }
}

private struct QuickplayPlayerLoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color(hex: "FF6B00"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: 60, height: 60)
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

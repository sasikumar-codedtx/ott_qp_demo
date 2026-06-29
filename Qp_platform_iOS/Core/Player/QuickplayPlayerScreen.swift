import os
import SwiftUI
import UIKit

struct QuickplayPlayerScreen: View {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ott.qp", category: "PlayerScreen")
    let content: QuickplayPlaybackContent
    let episodes: [StorefrontItem]
    let seasons: [ContentSeason]
    let onPlayEpisode: ((StorefrontItem) -> Void)?
    let onDismiss: () -> Void
    @ObservedObject var engine: QuickplayPlayerEngine

    init(content: QuickplayPlaybackContent, engine: QuickplayPlayerEngine, episodes: [StorefrontItem] = [], seasons: [ContentSeason] = [], onPlayEpisode: ((StorefrontItem) -> Void)? = nil, onDismiss: @escaping () -> Void) {
        self.content = content
        self.engine = engine
        self.episodes = episodes
        self.seasons = seasons
        self.onPlayEpisode = onPlayEpisode
        self.onDismiss = onDismiss
    }
    @State private var screenOpenTime: Double = CFAbsoluteTimeGetCurrent()
    @State private var controlsVisible = false
    @State private var hideTask: Task<Void, Never>?
    @State private var isSeeking = false
    @State private var seekPosition: Double = 0
    @State private var wasPlayingBeforeSeek = false
    @State private var wasPlayingBeforeDialog = false
    @State private var showQualityDialog = false
    @State private var showSubtitleDialog = false
    @State private var showSpeedSheet = false
    @State private var showEpisodesPanel = false
    @State private var loadedEpisodes: [StorefrontItem] = []
    @State private var loadedSeasons: [ContentSeason] = []
    @State private var isLoadingEpisodes = false
    @State private var selectedSeason: ContentSeason?
    @State private var seekFeedback: SeekFeedback? = nil
    @State private var seekDismissTask: Task<Void, Never>? = nil
    @State private var showNextEpisodeCard = false
    @State private var nextEpisodeTask: Task<Void, Never>? = nil

    private var effectiveEpisodes: [StorefrontItem] { episodes.isEmpty ? loadedEpisodes : episodes }
    private var effectiveSeasons: [ContentSeason] { seasons.isEmpty ? loadedSeasons : seasons }

    private var nextEpisode: StorefrontItem? {
        guard let idx = effectiveEpisodes.firstIndex(where: { $0.id == content.contentId }),
              idx + 1 < effectiveEpisodes.count else { return nil }
        return effectiveEpisodes[idx + 1]
    }

    private func loadEpisodesIfNeeded() async {
        guard effectiveEpisodes.isEmpty,
              content.contentType != .movie,
              content.contentType != .channel,
              let seriesId = content.seriesId?.nilIfEmpty else { return }
        isLoadingEpisodes = true
        defer { isLoadingEpisodes = false }
        do {
            let bundle = try await GetContentEpisodesUseCase(
                repository: AppContainer.shared.contentDetailRepository
            ).execute(seriesID: seriesId)
            loadedEpisodes = bundle.episodes
            loadedSeasons = bundle.seasons
            if selectedSeason == nil {
                selectedSeason = bundle.selectedSeason ?? bundle.seasons.first
            }
        } catch {}
    }

    private func selectSeason(_ season: ContentSeason) async {
        guard season.id != selectedSeason?.id,
              let seriesId = content.seriesId?.nilIfEmpty else { return }
        selectedSeason = season
        isLoadingEpisodes = true
        defer { isLoadingEpisodes = false }
        do {
            let fetched = try await GetContentEpisodesUseCase(
                repository: AppContainer.shared.contentDetailRepository
            ).execute(seriesID: seriesId, seasonID: season.id)
            loadedEpisodes = fetched
        } catch {}
    }

    private var windowSafeArea: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero
    }

    @ViewBuilder private var controlsOverlay: some View {
        let insets = windowSafeArea
        let subtitle: String? = content.episodeSubtitle(episodes: effectiveEpisodes, seasons: effectiveSeasons) ?? content.playerSubtitle
        let nextAction: (() -> Void)? = nextEpisode.map { next in { onPlayEpisode?(next) } }
        QuickplayPlayerControlsOverlay(
            engine: engine,
            title: content.title,
            subtitle: subtitle,
            contentType: content.contentType,
            isSeeking: $isSeeking,
            seekPosition: $seekPosition,
            showQualityDialog: $showQualityDialog,
            showSubtitleDialog: $showSubtitleDialog,
            showSpeedSheet: $showSpeedSheet,
            showEpisodesPanel: $showEpisodesPanel,
            seekFeedback: seekFeedback,
            onPlayNextEpisode: nextAction,
            safeTop: insets.top,
            safeLeading: insets.left,
            safeTrailing: insets.right,
            safeBottom: insets.bottom,
            onDismiss: dismissPlayer
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            QuickplayPlayerSurfaceView(engine: engine, isPrimary: true)
                .ignoresSafeArea()

            // Double-tap seek zones — under controls, over video
            doubleTapLayer

            if (!engine.isReady || engine.isBuffering) && !isSeeking {
                QuickplayPlayerLoadingView()
                    .transition(.opacity)
            }

            if let error = engine.error {
                errorView(error)
            }

            if engine.isFinished {
                let insets = windowSafeArea
                videoEndScreen(
                    safeTop: insets.top,
                    safeLeading: insets.left
                )
                .transition(.opacity)
                .zIndex(60)
            }

            if (controlsVisible || isSeeking) && !showEpisodesPanel {
                controlsOverlay.transition(.opacity)
            }


                if showQualityDialog {
                    QuickplayQualityDialog(engine: engine, isPresented: $showQualityDialog)
                        .transition(.opacity)
                        .zIndex(20)
                }

                #if canImport(FLPlayerInterface)
                if showSubtitleDialog {
                    QuickplaySubtitleDialog(engine: engine, isPresented: $showSubtitleDialog, contentLanguage: content.contentLanguage)
                        .transition(.opacity)
                        .zIndex(20)
                }
                #endif

                if showSpeedSheet {
                    SpeedSelectorView(engine: engine, isPresented: $showSpeedSheet)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(20)
                }

                if showEpisodesPanel {
                    PlayerEpisodesPanel(
                        episodes: effectiveEpisodes,
                        seasons: effectiveSeasons,
                        selectedSeason: selectedSeason,
                        currentContentId: content.contentId,
                        isLoading: isLoadingEpisodes,
                        isPresented: $showEpisodesPanel,
                        onSelectSeason: { season in Task { await selectSeason(season) } },
                        onSelectEpisode: { item in
                            showEpisodesPanel = false
                            onPlayEpisode?(item)
                        }
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(25)
                }

                if showNextEpisodeCard, let next = nextEpisode {
                    let insets = windowSafeArea
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            NextEpisodeCard(
                                next: next,
                                onTap: {
                                    nextEpisodeTask?.cancel()
                                    showNextEpisodeCard = false
                                    onPlayEpisode?(next)
                                },
                                onDismiss: {
                                    nextEpisodeTask?.cancel()
                                    withAnimation(.easeInOut(duration: 0.2)) { showNextEpisodeCard = false }
                                }
                            )
                            .padding(.trailing, insets.right + 16)
                        }
                        .padding(.bottom, insets.bottom + 90)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(35)
                }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.4), value: engine.isFinished)
        .animation(.easeInOut(duration: 0.3), value: engine.isReady)
        .animation(.easeInOut(duration: 0.2), value: engine.isBuffering)
        .animation(.easeInOut(duration: 0.25), value: controlsVisible)
        .animation(.easeInOut(duration: 0.22), value: showQualityDialog)
        .animation(.easeInOut(duration: 0.22), value: showSubtitleDialog)
        .animation(.easeInOut(duration: 0.22), value: showSpeedSheet)
        .animation(.easeInOut(duration: 0.18), value: seekFeedback)
        .animation(.spring(response: 0.4, dampingFraction: 0.88), value: showNextEpisodeCard)
        .task {
            if engine.loadedContentId != content.contentId {
                await engine.load(content: content)
            }
            await loadEpisodesIfNeeded()
            if selectedSeason == nil { selectedSeason = effectiveSeasons.first }
        }
        .onAppear {
            lockLandscape()
            engine.isFullscreenSurfaceActive = true
        }
        .onDisappear {
            lockPortrait()
            engine.isFullscreenSurfaceActive = false
            hideTask?.cancel()
            nextEpisodeTask?.cancel()
        }
        .onChange(of: engine.isReady) { _, ready in
            guard ready else { return }
            Self.logger.debug("[Controls] isReady fired → showing controls t=+\(elapsed())ms")
            controlsVisible = true
            scheduleHide()
        }
        .onChange(of: isSeeking) { (_: Bool, seeking: Bool) in
            if seeking {
                wasPlayingBeforeSeek = engine.isPlaying
                engine.pause()
            } else {
                if wasPlayingBeforeSeek { engine.play() }
            }
        }
        .onChange(of: showQualityDialog) { _, showing in
            if showing {
                wasPlayingBeforeDialog = engine.isPlaying
                engine.pause()
                hideTask?.cancel()
                controlsVisible = true
            } else {
                scheduleHide()
                guard wasPlayingBeforeDialog else { return }
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    engine.play()
                }
            }
        }
        .onChange(of: showSubtitleDialog) { _, showing in
            if showing {
                wasPlayingBeforeDialog = engine.isPlaying
                engine.pause()
                hideTask?.cancel()
                withAnimation(.easeInOut(duration: 0.22)) { controlsVisible = false }
            } else {
                withAnimation(.easeInOut(duration: 0.22)) { controlsVisible = true }
                scheduleHide()
                guard wasPlayingBeforeDialog else { return }
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    engine.play()
                }
            }
        }
        .onChange(of: showEpisodesPanel) { _, showing in
            if showing {
                wasPlayingBeforeDialog = engine.isPlaying
                engine.pause()
                hideTask?.cancel()
                controlsVisible = false
            } else {
                scheduleHide()
                guard wasPlayingBeforeDialog else { return }
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    engine.play()
                }
            }
        }
        .onChange(of: engine.currentTime) { _, t in
            guard !showNextEpisodeCard,
                  engine.duration > 0,
                  nextEpisode != nil,
                  engine.duration - t <= 15 else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) { showNextEpisodeCard = true }
            nextEpisodeTask?.cancel()
            nextEpisodeTask = Task {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let next = nextEpisode else { return }
                    showNextEpisodeCard = false
                    onPlayEpisode?(next)
                }
            }
        }
        .onChange(of: engine.isFinished) { _, finished in
            guard finished, nextEpisode == nil else { return }
            Task {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await MainActor.run { dismissPlayer() }
            }
        }
        .onChange(of: content.contentId) { _, _ in
            engine.release()
            showNextEpisodeCard = false
            nextEpisodeTask?.cancel()
            loadedEpisodes = []
            loadedSeasons = []
            selectedSeason = nil
            Task { await engine.load(content: content); await loadEpisodesIfNeeded() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            Self.logger.warning("⚠️ Memory warning — screen level | isReady=\(engine.isReady) isBuffering=\(engine.isBuffering) currentTime=\(String(format: "%.1f", engine.currentTime))s")
        }
    }

    // MARK: Video end screen

    @State private var endThumbnail: UIImage? = nil

    private func videoEndScreen(safeTop: CGFloat, safeLeading: CGFloat) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let thumb = endThumbnail {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 24)
                    .overlay(Color.black.opacity(0.55))
            }

            NavigationChromeButton(icon: AppIcons.Navigation.back, action: dismissPlayer)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, safeLeading + 16)
                .padding(.top, safeTop + 12)
        }
        .task {
            endThumbnail = await engine.thumbnailImage(at: engine.duration * 0.1)
        }
    }

    // MARK: Double-tap zones

    private func elapsed() -> Int { Int((CFAbsoluteTimeGetCurrent() - screenOpenTime) * 1000) }

    private var doubleTapLayer: some View {
        HStack(spacing: 0) {
            Color.clear.contentShape(Rectangle())
                .gesture(
                    TapGesture(count: 2).onEnded {
                        Self.logger.debug("[Controls] double-tap left — isReady=\(engine.isReady) t=+\(elapsed())ms")
                        handleSeekTap(delta: -10)
                    }
                    .exclusively(before: TapGesture(count: 1).onEnded {
                        Self.logger.debug("[Controls] single-tap left — isReady=\(engine.isReady) controlsVisible=\(controlsVisible) t=+\(elapsed())ms")
                        toggleControls()
                    })
                )
            Color.clear.contentShape(Rectangle())
                .gesture(
                    TapGesture(count: 2).onEnded {
                        Self.logger.debug("[Controls] double-tap right — isReady=\(engine.isReady) t=+\(elapsed())ms")
                        handleSeekTap(delta: 10)
                    }
                    .exclusively(before: TapGesture(count: 1).onEnded {
                        Self.logger.debug("[Controls] single-tap right — isReady=\(engine.isReady) controlsVisible=\(controlsVisible) t=+\(elapsed())ms")
                        toggleControls()
                    })
                )
        }
        .ignoresSafeArea()
    }

    private func handleSeekTap(delta: Double) {
        engine.seek(to: min(max(engine.currentTime + delta, 0), engine.duration))
        let side: SeekFeedback.Side = delta > 0 ? .forward : .backward
        let amount = Int(abs(delta))
        // Accumulate amount when the same side is tapped rapidly
        if let current = seekFeedback, current.side == side {
            seekFeedback = SeekFeedback(side: side, amount: current.amount + amount)
        } else {
            seekFeedback = SeekFeedback(side: side, amount: amount)
        }
        showControls()
        seekDismissTask?.cancel()
        seekDismissTask = Task {
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            await MainActor.run { seekFeedback = nil }
        }
    }

    // MARK: Orientation

    private func lockLandscape() {
        AppDelegate.orientationLock = .landscape
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func lockPortrait() {
        AppDelegate.orientationLock = .portrait
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }

    private func dismissPlayer() {
        lockPortrait()
        onDismiss()
    }

    // MARK: Controls visibility

    private func showControls() {
        Self.logger.debug("[Controls] showControls called — isReady=\(engine.isReady) isPlaying=\(engine.isPlaying)")
        controlsVisible = true
        scheduleHide()
    }

    private func toggleControls() {
        if controlsVisible {
            Self.logger.debug("[Controls] tap → hiding controls")
            hideTask?.cancel()
            withAnimation(.easeInOut(duration: 0.22)) { controlsVisible = false }
        } else {
            Self.logger.debug("[Controls] tap → showing controls — isReady=\(engine.isReady) isPlaying=\(engine.isPlaying)")
            showControls()
        }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled,
                  !isSeeking,
                  !showQualityDialog,
                  !showSubtitleDialog,
                  !showSpeedSheet,
                  !showEpisodesPanel else { return }
            await MainActor.run {
                Self.logger.debug("[Controls] auto-hide fired")
                withAnimation(.easeInOut(duration: 0.22)) { controlsVisible = false }
            }
        }
    }

    // MARK: Error

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
            Button("Dismiss", action: dismissPlayer)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "FF8A00"))
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

}

// MARK: - Speed selector (full-screen snapping rail)

struct SpeedSelectorView: View {
    @ObservedObject var engine: QuickplayPlayerEngine
    @Binding var isPresented: Bool

    private struct SpeedOption {
        let value: Float
        let label: String
        let sublabel: String?
    }

    private let options: [SpeedOption] = [
        .init(value: 0.5,  label: "0.5x",  sublabel: nil),
        .init(value: 0.75, label: "0.75x", sublabel: nil),
        .init(value: 1.0,  label: "1x",    sublabel: "Normal"),
        .init(value: 1.25, label: "1.25x", sublabel: nil),
        .init(value: 1.5,  label: "1.5x",  sublabel: nil),
    ]

    @State private var selected: Float = 1.0
    @State private var dragIndex: Int? = nil
    @State private var trackWidth: CGFloat = 0

    // Which stop to visually highlight — drag candidate takes priority
    private var activeIndex: Int {
        dragIndex ?? (options.firstIndex(where: { $0.value == selected }) ?? 2)
    }

    private func thumbFraction(for index: Int) -> CGFloat {
        guard options.count > 1 else { return 0 }
        return CGFloat(index) / CGFloat(options.count - 1)
    }

    var body: some View {
        let insets = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero

        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 16) {
                    rail
                        .padding(.leading, insets.left + 56)

                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                    .padding(.trailing, insets.right + 20)
                }
                .padding(.top, 20)

                labels
                    .padding(.leading, insets.left + 56)
                    .padding(.trailing, insets.right + 80)
                    .padding(.top, 14)
                    .padding(.bottom, insets.bottom)
            }
            .background(
                Color(hex: "1A1A1A")
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .onAppear { selected = 1.0 }
    }

    // MARK: Rail

    private var rail: some View {
        track
    }

    private var track: some View {
        ZStack {
            // Canvas: background + fill lines
            Canvas { ctx, size in
                let trackH: CGFloat = 3
                let cy = size.height / 2
                let fillX = size.width * thumbFraction(for: activeIndex)

                var bg = Path()
                bg.addRoundedRect(
                    in: CGRect(x: 0, y: cy - trackH / 2, width: size.width, height: trackH),
                    cornerSize: CGSize(width: trackH / 2, height: trackH / 2)
                )
                ctx.fill(bg, with: .color(.white.opacity(0.2)))

                if fillX > 0 {
                    var fill = Path()
                    fill.addRoundedRect(
                        in: CGRect(x: 0, y: cy - trackH / 2, width: fillX, height: trackH),
                        cornerSize: CGSize(width: trackH / 2, height: trackH / 2)
                    )
                    ctx.fill(fill, with: .color(.white))
                }
            }

            // Thumb pill — overlaid, position driven by activeIndex
            GeometryReader { geo in
                let thumbW: CGFloat = 54
                let thumbH: CGFloat = 32
                let cx = max(thumbW / 2, min(geo.size.width - thumbW / 2,
                                             geo.size.width * thumbFraction(for: activeIndex)))
                RoundedRectangle(cornerRadius: thumbH / 2, style: .continuous)
                    .fill(Color.white.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: thumbH / 2, style: .continuous)
                            .stroke(Color.white, lineWidth: 1.2)
                    )
                    .frame(width: thumbW, height: thumbH)
                    .position(x: cx, y: geo.size.height / 2)
            }
        }
        .frame(height: 32)
        .contentShape(Rectangle())
        .background(
            GeometryReader { g in
                Color.clear
                    .onAppear { trackWidth = g.size.width }
                    .onChange(of: g.size.width) { _, w in trackWidth = w }
            }
        )
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    guard trackWidth > 0 else { return }
                    let raw = (value.location.x / trackWidth) * CGFloat(options.count - 1)
                    let idx = Int(max(0, min(CGFloat(options.count - 1), raw.rounded())))
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
                        dragIndex = idx
                    }
                }
                .onEnded { _ in
                    guard let idx = dragIndex else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        selected = options[idx].value
                        dragIndex = nil
                    }
                    engine.setPlaybackRate(options[idx].value)
                }
        )
    }

    private var labels: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let opt = options[i]
                let isSelected = opt.value == selected
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        selected = opt.value
                        dragIndex = nil
                    }
                    engine.setPlaybackRate(opt.value)
                } label: {
                    VStack(spacing: 4) {
                        Text(opt.label)
                            .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.45))
                        if let sub = opt.sublabel {
                            Text(sub)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(.white.opacity(isSelected ? 0.65 : 0.3))
                        } else {
                            // Maintain height alignment when no sublabel
                            Text(" ").font(.system(size: 11)).hidden()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Seek feedback

struct SeekFeedback: Equatable {
    enum Side { case forward, backward }
    let side: Side
    let amount: Int
}


// MARK: - Loading view

private struct QuickplayPlayerLoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.2), lineWidth: 3)
            Circle().trim(from: 0, to: 0.3)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: 36, height: 36)
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) { rotation = 360 }
        }
    }
}

// MARK: - Content extensions

extension QuickplayPlaybackContent {
    var playerSubtitle: String? {
        var parts: [String] = []
        if let genre { parts.append(genre) }
        if let rating { parts.append(rating) }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    func episodeSubtitle(episodes: [StorefrontItem], seasons: [ContentSeason]) -> String? {
        guard contentType == .episode || contentType == .series || contentType == .show else { return nil }
        var parts: [String] = []
        if seasons.count > 1,
           let seasonIdx = seasons.firstIndex(where: { $0.id == seasonId }) {
            parts.append("S\(seasonIdx + 1)")
        } else if !seasons.isEmpty {
            parts.append("S1")
        }
        if let epIdx = episodes.firstIndex(where: { $0.id == contentId }) {
            parts.append("E\(epIdx + 1)")
        }
        if let date = releaseDate, let formatted = Self.formatReleaseDate(date) {
            parts.append(formatted)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    private static func formatReleaseDate(_ raw: String) -> String? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) {
                let out = DateFormatter()
                out.dateFormat = "MMM d, yyyy"
                out.locale = Locale(identifier: "en_US")
                return out.string(from: date)
            }
        }
        return nil
    }

    var supportsTimedQuizOverlay: Bool {
        switch contentType {
        case .series, .episode, .show: return true
        case .movie, .channel: return false
        }
    }

    var supportsSportsLiveOverlay: Bool {
        if contentType == .channel { return true }
        let t = title.lowercased()
        return t.contains("sport") || t.contains("cricket") || t.contains("football") || t.contains("match") || t.contains("live")
    }
}

// MARK: - Quiz / Sports prompts (unchanged)

private struct PlayerQuizPrompt: Identifiable, Equatable {
    let id: String; let question: String; let options: [PlayerQuizOption]
    static let golfDemo = PlayerQuizPrompt(id: "golf-demo-question",
        question: "How many holes are contained in a typical golf course?",
        options: [.init(id: "A", title: "18", isCorrect: true), .init(id: "B", title: "10", isCorrect: false),
                  .init(id: "C", title: "12", isCorrect: false), .init(id: "D", title: "4", isCorrect: false)])
}

private struct PlayerQuizOption: Identifiable, Equatable {
    let id: String; let title: String; let isCorrect: Bool
}

private struct PlayerSportsPrompt: Identifiable, Equatable {
    let id: String; let matchTitle: String; let scoreLine: String
    let question: String; let options: [PlayerQuizOption]
    static let matchDemo = PlayerSportsPrompt(id: "sports-live-demo-question",
        matchTitle: "Live Fan Pulse", scoreLine: "IND 148/3  •  16.2 overs",
        question: "Who will win the next power moment?",
        options: [.init(id: "A", title: "India", isCorrect: true), .init(id: "B", title: "Opponent", isCorrect: false),
                  .init(id: "C", title: "Super Over", isCorrect: false), .init(id: "D", title: "Rain Break", isCorrect: false)])
}

private struct PlayerQuizOverlayView: View {
    let prompt: PlayerQuizPrompt; let onDismiss: () -> Void
    @State private var selectedOptionID: String?
    @State private var remainingSeconds = 20
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 14) {
                Text("\(remainingSeconds)")
                    .font(.system(size: 18, weight: .black)).foregroundStyle(.white)
                    .frame(width: 56, height: 40)
                    .background(Capsule().fill(LinearGradient(colors: [Color(hex: "FF7A18"), Color(hex: "8C1EFF")], startPoint: .leading, endPoint: .trailing)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1))

                Text(prompt.question)
                    .font(.system(size: 17, weight: .heavy)).foregroundStyle(.white)
                    .multilineTextAlignment(.center).lineLimit(3)
                    .padding(.horizontal, 22).padding(.vertical, 18)
                    .frame(maxWidth: .infinity, minHeight: 82)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: "292348").opacity(0.96), Color(hex: "121628").opacity(0.96)], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.75), lineWidth: 1.4))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(prompt.options) { option in
                        Button { select(option) } label: {
                            PlayerQuizOptionRow(option: option, selectedOptionID: selectedOptionID,
                                               correctOptionID: prompt.options.first(where: \.isCorrect)?.id)
                        }
                        .buttonStyle(.plain).disabled(selectedOptionID != nil)
                    }
                }
            }
            .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 22)
            .background(RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "2F194A").opacity(0.9), Color(hex: "111520").opacity(0.94), Color(hex: "311108").opacity(0.86)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(LinearGradient(colors: [.white.opacity(0.45), Color(hex: "FF8A00").opacity(0.55), Color(hex: "8A44FF").opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.1))
            .shadow(color: .black.opacity(0.45), radius: 28, x: 0, y: -8)
            .padding(.horizontal, 14).padding(.bottom, 18)
        }
        .task(id: prompt.id) {
            remainingSeconds = 20
            while remainingSeconds > 0 && selectedOptionID == nil {
                try? await Task.sleep(for: .seconds(1))
                if selectedOptionID == nil { remainingSeconds -= 1 }
            }
            if remainingSeconds == 0 && selectedOptionID == nil { onDismiss() }
        }
        .onDisappear { dismissTask?.cancel() }
    }

    private func select(_ option: PlayerQuizOption) {
        guard selectedOptionID == nil else { return }
        selectedOptionID = option.id
        UINotificationFeedbackGenerator().notificationOccurred(option.isCorrect ? .success : .error)
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run { onDismiss() }
        }
    }
}

private struct PlayerQuizOptionRow: View {
    let option: PlayerQuizOption; let selectedOptionID: String?; let correctOptionID: String?
    private var isLocked: Bool { selectedOptionID != nil }
    private var isSelected: Bool { selectedOptionID == option.id }
    private var isCorrect: Bool { correctOptionID == option.id }

    var body: some View {
        HStack(spacing: 10) {
            Text(option.id).font(.system(size: 14, weight: .black)).foregroundStyle(Color(hex: "FF8A00"))
                .frame(width: 28, height: 28).background(Circle().fill(Color.black.opacity(0.28)))
            Text(option.title).font(.system(size: 17, weight: .heavy)).foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
        }
        .padding(.horizontal, 13).frame(height: 54)
        .background(backgroundFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(borderColor, lineWidth: isLocked ? 1.5 : 1))
        .scaleEffect(isSelected ? 1.02 : 1)
    }

    private var backgroundFill: LinearGradient {
        if isLocked && isCorrect { return LinearGradient(colors: [Color(hex: "0E7A42"), Color(hex: "16A85D")], startPoint: .topLeading, endPoint: .bottomTrailing) }
        if isLocked && isSelected && !isCorrect { return LinearGradient(colors: [Color(hex: "8D1F25"), Color(hex: "D44333")], startPoint: .topLeading, endPoint: .bottomTrailing) }
        return LinearGradient(colors: [Color(hex: "24283A").opacity(0.96), Color(hex: "10131F").opacity(0.96)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var borderColor: Color {
        if isLocked && isCorrect { return Color(hex: "62F59B") }
        if isLocked && isSelected { return Color(hex: "FF6A4B") }
        return .white.opacity(0.28)
    }
}

// MARK: - Episodes Panel

private struct PlayerEpisodesPanel: View {
    let episodes: [StorefrontItem]
    let seasons: [ContentSeason]
    let selectedSeason: ContentSeason?
    let currentContentId: String
    let isLoading: Bool
    @Binding var isPresented: Bool
    let onSelectSeason: (ContentSeason) -> Void
    let onSelectEpisode: (StorefrontItem) -> Void

    private var safeInsets: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero
    }

    var body: some View {
        let insets = safeInsets
        ZStack {
            Color(hex: "141414")
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Header
                HStack(alignment: .center) {
                    if seasons.isEmpty {
                        Text("Episodes")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    } else {
                        Menu {
                            ForEach(seasons) { season in
                                Button {
                                    onSelectSeason(season)
                                } label: {
                                    HStack {
                                        Text(season.title)
                                        if season.id == selectedSeason?.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedSeason?.title ?? seasons.first?.title ?? "Episodes")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.7)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
                .padding(.leading, insets.left + 20)
                .padding(.trailing, insets.right + 20)
                .padding(.top, 20)
                .padding(.bottom, 4)

                // Episode list fills all remaining height
                GeometryReader { geo in
                    let hPad = insets.left + insets.right + 40
                    let tileWidth = max(160, (geo.size.width - hPad - 3 * 16) / 4.0)
                    if isLoading {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 16) {
                                ForEach(0..<5, id: \.self) { _ in
                                    EpisodeTileShimmer(tileWidth: tileWidth)
                                }
                            }
                            .padding(.leading, insets.left + 20)
                            .padding(.trailing, insets.right + 20)
                            .padding(.bottom, insets.bottom + 16)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 16) {
                                    ForEach(Array(episodes.enumerated()), id: \.element.id) { index, episode in
                                        EpisodeTile(
                                            episode: episode,
                                            episodeNumber: index + 1,
                                            isCurrent: episode.id == currentContentId,
                                            tileWidth: tileWidth,
                                            onTap: { onSelectEpisode(episode) }
                                        )
                                        .id(episode.id)
                                    }
                                }
                                .padding(.leading, insets.left + 20)
                                .padding(.trailing, insets.right + 20)
                                .padding(.bottom, insets.bottom + 16)
                            }
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                if let id = episodes.first(where: { $0.id == currentContentId })?.id {
                                    proxy.scrollTo(id, anchor: .leading)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
    }
}

// MARK: - Next Episode Card

private struct NextEpisodeCard: View {
    let next: StorefrontItem
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var fillProgress: CGFloat = 0

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .leading) {
                // Background fill progress
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: proxy.size.width * fillProgress)
                }

                HStack(spacing: 10) {
                    // Thumbnail
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.1))
                        if let url = next.imageURL(for: "0-16x9", width: 160) {
                            AsyncImage(url: url) { phase in
                                if let img = phase.image {
                                    img.resizable().scaledToFill()
                                }
                            }
                            .clipped()
                        }
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .frame(width: 68, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Up Next")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                        Text(next.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .frame(width: 260, height: 58)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.linear(duration: 5)) { fillProgress = 1.0 }
        }
    }
}

// MARK: - Episode Tile

private struct EpisodeTile: View {
    let episode: StorefrontItem
    let episodeNumber: Int
    let isCurrent: Bool
    let tileWidth: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "2A2A2A"))
                    if let url = episode.imageURL(for: "0-16x9", width: 320) {
                        AsyncImage(url: url) { phase in
                            if let img = phase.image {
                                img.resizable().scaledToFill()
                            }
                        }
                        .clipped()
                    }
                    if !isCurrent {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.55))
                                .frame(width: 36, height: 36)
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .offset(x: 1)
                        }
                    }
                    if let progress = episode.progress, progress > 0.01 {
                        VStack {
                            Spacer()
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle().fill(Color.white.opacity(0.3)).frame(height: 3)
                                    Rectangle().fill(Color.red).frame(width: geo.size.width * CGFloat(progress), height: 3)
                                }
                            }
                            .frame(height: 3)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .frame(width: tileWidth, height: tileWidth * 9 / 16)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Text("\(episodeNumber). \(episode.title)")
                    .font(.system(size: 12, weight: isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? .white : .white.opacity(0.55))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .padding(.top, 10)

                if let runtime = episode.runtimeSeconds {
                    Text("\(runtime / 60)m")
                        .font(.system(size: 11))
                        .foregroundStyle(isCurrent ? .white : .white.opacity(0.55))
                        .padding(.top, 4)
                }

                Text(episode.description)
                    .font(.system(size: 11))
                    .foregroundStyle(isCurrent ? .white : .white.opacity(0.55))
                    .lineLimit(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(width: tileWidth)
        }
        .buttonStyle(.plain)
    }
}

private struct EpisodeTileShimmer: View {
    let tileWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShimmerView()
                .frame(width: tileWidth, height: tileWidth * 9 / 16)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            ShimmerView()
                .frame(width: tileWidth * 0.7, height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.top, 8)

            ShimmerView()
                .frame(width: tileWidth * 0.25, height: 11)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    ShimmerView()
                        .frame(width: i == 2 ? tileWidth * 0.5 : tileWidth, height: 11)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(.top, 4)
            .frame(minHeight: 48, alignment: .top)
        }
        .frame(width: tileWidth)
    }
}

private struct PlayerSportsOverlayView: View {
    let prompt: PlayerSportsPrompt; let onDismiss: () -> Void
    @State private var selectedOptionID: String?
    @State private var remainingSeconds = 15
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prompt.matchTitle).font(.system(size: 13, weight: .black)).foregroundStyle(Color(hex: "F8D24A")).textCase(.uppercase)
                        Text(prompt.scoreLine).font(.system(size: 22, weight: .black)).foregroundStyle(.white)
                    }
                    Spacer()
                    Text("\(remainingSeconds)s").font(.system(size: 15, weight: .black)).foregroundStyle(.white)
                        .frame(width: 52, height: 34).background(Capsule().fill(Color(hex: "D71920")))
                }
                Text(prompt.question).font(.system(size: 19, weight: .heavy)).foregroundStyle(.white).lineLimit(2)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(prompt.options) { option in
                        Button { select(option) } label: {
                            PlayerQuizOptionRow(option: option, selectedOptionID: selectedOptionID,
                                               correctOptionID: prompt.options.first(where: \.isCorrect)?.id)
                        }
                        .buttonStyle(.plain).disabled(selectedOptionID != nil)
                    }
                }
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "1F2B53").opacity(0.96), Color(hex: "071421").opacity(0.98), Color(hex: "381206").opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(LinearGradient(colors: [Color(hex: "F8D24A"), Color(hex: "D71920"), .white.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2))
            .shadow(color: .black.opacity(0.48), radius: 28, x: 0, y: -8)
            .padding(.horizontal, 14).padding(.bottom, 18)
        }
        .task(id: prompt.id) {
            remainingSeconds = 15
            while remainingSeconds > 0 && selectedOptionID == nil {
                try? await Task.sleep(for: .seconds(1))
                if selectedOptionID == nil { remainingSeconds -= 1 }
            }
            if remainingSeconds == 0 && selectedOptionID == nil { onDismiss() }
        }
        .onDisappear { dismissTask?.cancel() }
    }

    private func select(_ option: PlayerQuizOption) {
        guard selectedOptionID == nil else { return }
        selectedOptionID = option.id
        UINotificationFeedbackGenerator().notificationOccurred(option.isCorrect ? .success : .error)
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run { onDismiss() }
        }
    }
}

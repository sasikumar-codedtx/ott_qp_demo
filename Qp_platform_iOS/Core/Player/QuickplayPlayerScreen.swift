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
    @State private var activeQuizPrompt: PlayerQuizPrompt?
    @State private var activeSportsPrompt: PlayerSportsPrompt?
    @State private var lastQuizBucket = -1
    @State private var lastSportsBucket = -1
    @State private var quizDemoTask: Task<Void, Never>?

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

            if let activeQuizPrompt {
                PlayerQuizOverlayView(prompt: activeQuizPrompt) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                        self.activeQuizPrompt = nil
                    }
                    scheduleHide()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(40)
            }

            if let activeSportsPrompt {
                PlayerSportsOverlayView(prompt: activeSportsPrompt) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                        self.activeSportsPrompt = nil
                    }
                    scheduleHide()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(40)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: controlsVisible)
        .animation(.easeInOut(duration: 0.2), value: showQualityDialog)
        .animation(.easeInOut(duration: 0.2), value: showSubtitleDialog)
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: activeQuizPrompt)
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: activeSportsPrompt)
        .task {
            await engine.load(content: content)
            scheduleHide()
            scheduleDemoQuizIfNeeded()
        }
        .onDisappear {
            hideTask?.cancel()
            quizDemoTask?.cancel()
            engine.release()
        }
        .onChange(of: engine.currentTime) { _, newValue in
            triggerQuizIfNeeded(at: newValue)
        }
        .onTapGesture {
            guard activeQuizPrompt == nil, activeSportsPrompt == nil else { return }
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

    private func scheduleDemoQuizIfNeeded() {
        quizDemoTask?.cancel()
        guard content.supportsTimedQuizOverlay || content.supportsSportsLiveOverlay else { return }
        quizDemoTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if content.supportsTimedQuizOverlay {
                    presentQuiz(bucket: 0)
                } else if content.supportsSportsLiveOverlay {
                    presentSportsPrompt(bucket: 0)
                }
            }
        }
    }

    private func triggerQuizIfNeeded(at currentTime: Double) {
        guard currentTime >= 300 else { return }
        let bucket = Int(currentTime / 300)
        guard bucket > 0 else { return }

        if content.supportsTimedQuizOverlay,
           bucket != lastQuizBucket,
           activeQuizPrompt == nil,
           activeSportsPrompt == nil {
            presentQuiz(bucket: bucket)
        } else if content.supportsSportsLiveOverlay,
                  bucket != lastSportsBucket,
                  activeQuizPrompt == nil,
                  activeSportsPrompt == nil {
            presentSportsPrompt(bucket: bucket)
        }
    }

    private func presentQuiz(bucket: Int) {
        guard content.supportsTimedQuizOverlay, activeQuizPrompt == nil else { return }
        lastQuizBucket = bucket
        hideTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            controlsVisible = false
            activeQuizPrompt = .golfDemo
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func presentSportsPrompt(bucket: Int) {
        guard content.supportsSportsLiveOverlay, activeSportsPrompt == nil else { return }
        lastSportsBucket = bucket
        hideTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            controlsVisible = false
            activeSportsPrompt = .matchDemo
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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

private extension QuickplayPlaybackContent {
    var supportsTimedQuizOverlay: Bool {
        switch contentType {
        case .series, .episode, .show:
            return true
        case .movie, .channel:
            return false
        }
    }

    var supportsSportsLiveOverlay: Bool {
        if contentType == .channel {
            return true
        }

        let normalizedTitle = title.lowercased()
        return normalizedTitle.contains("sport")
            || normalizedTitle.contains("cricket")
            || normalizedTitle.contains("football")
            || normalizedTitle.contains("match")
            || normalizedTitle.contains("live")
    }
}

private struct PlayerQuizPrompt: Identifiable, Equatable {
    let id: String
    let question: String
    let options: [PlayerQuizOption]

    static let golfDemo = PlayerQuizPrompt(
        id: "golf-demo-question",
        question: "How many holes are contained in a typical golf course?",
        options: [
            PlayerQuizOption(id: "A", title: "18", isCorrect: true),
            PlayerQuizOption(id: "B", title: "10", isCorrect: false),
            PlayerQuizOption(id: "C", title: "12", isCorrect: false),
            PlayerQuizOption(id: "D", title: "4", isCorrect: false)
        ]
    )
}

private struct PlayerQuizOption: Identifiable, Equatable {
    let id: String
    let title: String
    let isCorrect: Bool
}

private struct PlayerQuizOverlayView: View {
    let prompt: PlayerQuizPrompt
    let onDismiss: () -> Void

    @State private var selectedOptionID: String?
    @State private var remainingSeconds = 20
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 14) {
                timerBadge

                Text(prompt.question)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity, minHeight: 82)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "292348").opacity(0.96),
                                        Color(hex: "121628").opacity(0.96)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.75), lineWidth: 1.4)
                    )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(prompt.options) { option in
                        Button {
                            select(option)
                        } label: {
                            PlayerQuizOptionRow(
                                option: option,
                                selectedOptionID: selectedOptionID,
                                correctOptionID: prompt.options.first(where: \.isCorrect)?.id
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedOptionID != nil)
                    }
                }

                HStack(spacing: 12) {
                    PlayerQuizLifelineView(title: "50:50", systemImage: "circle.lefthalf.filled")
                    PlayerQuizLifelineView(title: "Retry", systemImage: "arrow.clockwise")
                    PlayerQuizLifelineView(title: "Ask", systemImage: "person.wave.2")
                    PlayerQuizLifelineView(title: "Stats", systemImage: "chart.bar.xaxis")
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 22)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "2F194A").opacity(0.9),
                                    Color(hex: "111520").opacity(0.94),
                                    Color(hex: "311108").opacity(0.86)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color(hex: "FF8A00").opacity(0.55),
                                Color(hex: "8A44FF").opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.1
                    )
            )
            .shadow(color: Color.black.opacity(0.45), radius: 28, x: 0, y: -8)
            .padding(.horizontal, 14)
            .padding(.bottom, 18)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.02),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.48)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .task(id: prompt.id) {
            remainingSeconds = 20
            while remainingSeconds > 0 && selectedOptionID == nil {
                try? await Task.sleep(for: .seconds(1))
                if selectedOptionID == nil {
                    remainingSeconds -= 1
                }
            }
            if remainingSeconds == 0 && selectedOptionID == nil {
                onDismiss()
            }
        }
        .onDisappear {
            dismissTask?.cancel()
        }
    }

    private var timerBadge: some View {
        Text("\(remainingSeconds)")
            .font(.system(size: 18, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 56, height: 40)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF7A18"), Color(hex: "8C1EFF")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1))
            .shadow(color: Color(hex: "FF7A18").opacity(0.35), radius: 14, x: 0, y: 4)
    }

    private func select(_ option: PlayerQuizOption) {
        guard selectedOptionID == nil else { return }
        selectedOptionID = option.id
        UINotificationFeedbackGenerator().notificationOccurred(option.isCorrect ? .success : .error)
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                onDismiss()
            }
        }
    }
}

private struct PlayerQuizOptionRow: View {
    let option: PlayerQuizOption
    let selectedOptionID: String?
    let correctOptionID: String?

    private var isLocked: Bool { selectedOptionID != nil }
    private var isSelected: Bool { selectedOptionID == option.id }
    private var isCorrect: Bool { correctOptionID == option.id }

    var body: some View {
        HStack(spacing: 10) {
            Text(option.id)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(Color(hex: "FF8A00"))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.black.opacity(0.28)))

            Text(option.title)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
        .padding(.horizontal, 13)
        .frame(height: 54)
        .background(backgroundFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: isLocked ? 1.5 : 1)
        )
        .scaleEffect(isSelected ? 1.02 : 1)
    }

    private var backgroundFill: LinearGradient {
        if isLocked && isCorrect {
            return LinearGradient(
                colors: [Color(hex: "0E7A42"), Color(hex: "16A85D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if isLocked && isSelected && !isCorrect {
            return LinearGradient(
                colors: [Color(hex: "8D1F25"), Color(hex: "D44333")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [Color(hex: "24283A").opacity(0.96), Color(hex: "10131F").opacity(0.96)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        if isLocked && isCorrect { return Color(hex: "62F59B") }
        if isLocked && isSelected { return Color(hex: "FF6A4B") }
        return Color.white.opacity(0.28)
    }
}

private struct PlayerQuizLifelineView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
            Text(title)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white.opacity(0.9))
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct PlayerSportsPrompt: Identifiable, Equatable {
    let id: String
    let matchTitle: String
    let scoreLine: String
    let question: String
    let options: [PlayerQuizOption]

    static let matchDemo = PlayerSportsPrompt(
        id: "sports-live-demo-question",
        matchTitle: "Live Fan Pulse",
        scoreLine: "IND 148/3  •  16.2 overs",
        question: "Who will win the next power moment?",
        options: [
            PlayerQuizOption(id: "A", title: "India", isCorrect: true),
            PlayerQuizOption(id: "B", title: "Opponent", isCorrect: false),
            PlayerQuizOption(id: "C", title: "Super Over", isCorrect: false),
            PlayerQuizOption(id: "D", title: "Rain Break", isCorrect: false)
        ]
    )
}

private struct PlayerSportsOverlayView: View {
    let prompt: PlayerSportsPrompt
    let onDismiss: () -> Void

    @State private var selectedOptionID: String?
    @State private var remainingSeconds = 15
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prompt.matchTitle)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(Color(hex: "F8D24A"))
                            .textCase(.uppercase)
                        Text(prompt.scoreLine)
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Text("\(remainingSeconds)s")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 34)
                        .background(Capsule().fill(Color(hex: "D71920")))
                }

                Text(prompt.question)
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(prompt.options) { option in
                        Button {
                            select(option)
                        } label: {
                            PlayerQuizOptionRow(
                                option: option,
                                selectedOptionID: selectedOptionID,
                                correctOptionID: prompt.options.first(where: \.isCorrect)?.id
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedOptionID != nil)
                    }
                }

                HStack(spacing: 10) {
                    sportsMetric(title: "Win Meter", value: "68%")
                    sportsMetric(title: "Fans Playing", value: "24.8K")
                    sportsMetric(title: "Moments", value: "Live")
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1F2B53").opacity(0.96),
                                Color(hex: "071421").opacity(0.98),
                                Color(hex: "381206").opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "F8D24A"), Color(hex: "D71920"), Color.white.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.48), radius: 28, x: 0, y: -8)
            .padding(.horizontal, 14)
            .padding(.bottom, 18)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.02),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .task(id: prompt.id) {
            remainingSeconds = 15
            while remainingSeconds > 0 && selectedOptionID == nil {
                try? await Task.sleep(for: .seconds(1))
                if selectedOptionID == nil {
                    remainingSeconds -= 1
                }
            }
            if remainingSeconds == 0 && selectedOptionID == nil {
                onDismiss()
            }
        }
        .onDisappear {
            dismissTask?.cancel()
        }
    }

    private func sportsMetric(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func select(_ option: PlayerQuizOption) {
        guard selectedOptionID == nil else { return }
        selectedOptionID = option.id
        UINotificationFeedbackGenerator().notificationOccurred(option.isCorrect ? .success : .error)
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                onDismiss()
            }
        }
    }
}

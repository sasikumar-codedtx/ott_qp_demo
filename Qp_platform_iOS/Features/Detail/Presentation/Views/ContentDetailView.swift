import Combine
import SwiftUI

// MARK: - Sports hardcoded data

private struct SportsLiveChatMessage: Identifiable {
    let id: String
    let username: String
    let text: String
    let avatarLetter: String
    let colorHex: String
}

private let sportsLiveChatMessages: [SportsLiveChatMessage] = [
    .init(id: "1", username: "Wisley",  text: "\"What a stunning six!\"", avatarLetter: "W", colorHex: "E53935"),
    .init(id: "2", username: "Abhi",    text: "Fans are buzzing with excitement as India takes on Sri Lanka! \"What a match!\"", avatarLetter: "A", colorHex: "1E88E5"),
    .init(id: "3", username: "Samson",  text: "Sri Lanka is putting up a good fight!", avatarLetter: "S", colorHex: "43A047"),
    .init(id: "4", username: "Rohit",   text: "\"That was a brilliant boundary!\" one fan noted, while another added, \"I love the way our bowlers are performing today!\"", avatarLetter: "R", colorHex: "FB8C00"),
    .init(id: "5", username: "James",   text: "\"What a stunning six!\"", avatarLetter: "J", colorHex: "8E24AA"),
]

private struct ScorecardBatter: Identifiable {
    let id: String
    let name: String
    let dismissal: String
    let r: String
    let b: String
    let fours: String
    let sixes: String
    let sr: String
    let isAtCrease: Bool
}

private let scorecardInnningsData: [ScorecardBatter] = [
    .init(id: "1",  name: "R Sharma (c)",  dismissal: "b Wellalage",            r: "53", b: "48", fours: "7", sixes: "2", sr: "110.42", isAtCrease: false),
    .init(id: "2",  name: "S Gill",        dismissal: "b Wellalage",            r: "19", b: "25", fours: "2", sixes: "0", sr: "76.00",  isAtCrease: false),
    .init(id: "3",  name: "V Kohli",       dismissal: "c Shanaka b Wellalage",  r: "3",  b: "12", fours: "0", sixes: "0", sr: "25.00",  isAtCrease: false),
    .init(id: "4",  name: "I Kishan",      dismissal: "c Wellalage b Asalanka", r: "33", b: "61", fours: "1", sixes: "1", sr: "54.10",  isAtCrease: false),
    .init(id: "5",  name: "KL Rahul (wk)", dismissal: "lbw Wellalage",          r: "33", b: "61", fours: "1", sixes: "1", sr: "88.64",  isAtCrease: false),
    .init(id: "6",  name: "H Pandya",      dismissal: "c Markdu b Asalanka",    r: "5",  b: "18", fours: "0", sixes: "0", sr: "27.18",  isAtCrease: false),
    .init(id: "7",  name: "R Jadeja",      dismissal: "c Markdu b Asalanka",    r: "4",  b: "19", fours: "0", sixes: "0", sr: "21.05",  isAtCrease: false),
    .init(id: "8",  name: "A Patel",       dismissal: "c Markdu b Asalanka",    r: "26", b: "36", fours: "0", sixes: "1", sr: "72.22",  isAtCrease: false),
    .init(id: "9",  name: "J Bumrah",      dismissal: "c Dhanaka",              r: "5",  b: "12", fours: "0", sixes: "0", sr: "41.67",  isAtCrease: false),
    .init(id: "10", name: "K Yadav",       dismissal: "b Asalanka",             r: "0",  b: "1",  fours: "0", sixes: "0", sr: "0.00",   isAtCrease: false),
    .init(id: "11", name: "M Siraj",       dismissal: "Not Out",                r: "5",  b: "19", fours: "0", sixes: "0", sr: "26.32",  isAtCrease: true),
]

private struct ScorecardBowler: Identifiable {
    let id: String; let name: String; let o: String; let m: String
    let r: String; let w: String; let er: String
}

private let scorecardBowlingData: [ScorecardBowler] = [
    .init(id: "1", name: "K Rajitha",    o: "4.0",  m: "0", r: "30", w: "0", er: "7.50"),
    .init(id: "2", name: "M Theekshana", o: "9.1",  m: "0", r: "41", w: "1", er: "4.47"),
    .init(id: "3", name: "D Shanaka",    o: "3.0",  m: "0", r: "24", w: "0", er: "8.00"),
    .init(id: "4", name: "M Pathirana",  o: "4.0",  m: "0", r: "31", w: "0", er: "7.75"),
    .init(id: "5", name: "D Wellalage",  o: "10.0", m: "1", r: "40", w: "5", er: "4.00"),
    .init(id: "6", name: "D Silva",      o: "10.0", m: "0", r: "28", w: "0", er: "2.80"),
    .init(id: "7", name: "C Asalanka",   o: "9.0",  m: "1", r: "18", w: "4", er: "2.00"),
]

private struct DetailTabRowOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

private enum DetailPresentationKind: Equatable {
    case regular
    case showInteractive
    case sportsInteractive

    static func resolve(seed: StorefrontItem?, detail: ContentDetail) -> DetailPresentationKind {
        let terms = [
            seed?.customID,
            seed?.customSearchCategory,
            seed?.cardType,
            seed?.contentType,
            detail.contentType,
            detail.title,
            detail.genres.joined(separator: " ")
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: " ")
            .lowercased()

        if terms.contains("sport")
            || terms.contains("cricket")
            || terms.contains("football")
            || terms.contains("match")
            || terms.contains("liveevent")
            || terms.contains("live event") {
            return .sportsInteractive
        }

        if detail.supportsEpisodes
            || terms.contains("show")
            || terms.contains("series")
            || terms.contains("episode")
            || terms.contains("webseries")
            || terms.contains("tvseries") {
            return .showInteractive
        }

        return .regular
    }
}

struct ContentDetailView: View {
    @ObservedObject var viewModel: ContentDetailViewModel
    let engine: QuickplayPlayerEngine
    let onBack: () -> Void
    let onPlay: (ContentDetail, StorefrontItem?) -> Void
    var onPlayEpisode: ((StorefrontItem) -> Void)? = nil
    let onSelectRecommendation: (StorefrontItem) -> Void
    @State private var isDescriptionExpanded = false
    @State private var isVideoReady = false
    @State private var showDemoAlert = false
    @State private var isMomentSearchOverlayPresented = false
    @State private var isMockInteractionPresented = false
    @State private var mockInteractionSelection: String?
    @State private var mockInteractionShowsResult = false
    @State private var momentSearchDraft = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isMomentSearchFocused: Bool
    // Sports interactive
    @State private var selectedSportsTab = "Live Feed"
    @State private var liveChatInput = ""
    @State private var liveChatDemoMessages: [SportsLiveChatMessage] = []
    @State private var sportsPollAnswer: String? = nil
    @State private var scorecardTeamTab = "India"
    @State private var isTimeStampPresented = false
    @FocusState private var isChatInputFocused: Bool
    @State private var quizCountdown = 20
    @State private var quizIsLocked = false   // true when timer expires (NOT on tap)
    @State private var timerShakeOffset: CGFloat = 0
    @State private var showQuizConfetti = false
    @State private var isSeasonSheetPresented = false
    @State private var tabRowGlobalY: CGFloat = .greatestFiniteMagnitude

    private let recommendationColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
    private let momentColumns = [GridItem(.flexible(), spacing: 10)]
    private var isShowingLiveFeedDock: Bool {
        guard let detail = viewModel.detail else { return false }
        let kind = DetailPresentationKind.resolve(seed: viewModel.seed, detail: detail)
        return kind == .sportsInteractive && selectedSportsTab == "Live Feed"
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                content(width: proxy.size.width, height: proxy.size.height, safeAreaTop: proxy.safeAreaInsets.top)

                if let detail = viewModel.detail, isMomentSearchOverlayPresented {
                    momentSearchOverlay(detail: detail, bottomInset: proxy.safeAreaInsets.bottom)
                        .zIndex(20)
                }

                if let detail = viewModel.detail, isMockInteractionPresented {
                    let mediaH = proxy.size.width * 9 / 16
                    let quizH  = proxy.size.height - 58 - mediaH
                    quizOverlay(detail: detail, width: proxy.size.width)
                        .frame(width: proxy.size.width, height: max(200, quizH))
                        .ignoresSafeArea(edges: .bottom)
                        .zIndex(30)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))

                    // Quiz nav bar — overlaid over the player area (Figma: back | crown+score | game-controller)
                    quizNavBarOverlay(safeAreaTop: proxy.safeAreaInsets.top)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .ignoresSafeArea(edges: .top)
                        .zIndex(31)
                        .transition(.opacity)
                }

                // Live Feed input dock — floats above keyboard
                if isShowingLiveFeedDock {
                    sportsLiveInputDock
                        .padding(.bottom, max(keyboardHeight - proxy.safeAreaInsets.bottom, 0))
                        .zIndex(10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Time Stamp panel
                if isTimeStampPresented {
                    timeStampOverlay
                        .ignoresSafeArea(edges: .bottom)
                        .zIndex(25)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .animation(.easeInOut(duration: 0.22), value: isMomentSearchOverlayPresented)
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: isMockInteractionPresented)
            .animation(.spring(response: 0.38, dampingFraction: 0.88), value: isTimeStampPresented)
            .animation(.easeInOut(duration: 0.18), value: isShowingLiveFeedDock)
            // 3-phase quiz timer:
            //   Phase 1 — Answer (20 s): quizCountdown 20→0, user may tap.
            //   Phase 2 — Hold   (5 s):  quizIsLocked=true, quizCountdown 5→0, no input.
            //   Phase 3 — Reveal (5 s):  mockInteractionShowsResult=true, quizCountdown 5→0, then dismiss.
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                guard isMockInteractionPresented else { return }

                if !quizIsLocked {
                    // Answer phase — user can still change selection while timer runs
                    if quizCountdown > 0 {
                        quizCountdown -= 1
                        // Escalating haptics: light→medium→heavy as time runs out
                        let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
                        let hapticIntensity: CGFloat
                        if quizCountdown > 10 {
                            hapticStyle = .light; hapticIntensity = 0.35
                        } else if quizCountdown > 5 {
                            hapticStyle = .medium; hapticIntensity = 0.6
                        } else {
                            hapticStyle = .heavy; hapticIntensity = 0.9
                        }
                        UIImpactFeedbackGenerator(style: hapticStyle).impactOccurred(intensity: hapticIntensity)
                        // Shake/jitter the countdown number — more aggressive in the last 5 seconds
                        let shakeAmp: CGFloat = quizCountdown <= 5 ? 5 : 2
                        withAnimation(.spring(response: 0.06, dampingFraction: 0.2)) {
                            timerShakeOffset = shakeAmp
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.14, dampingFraction: 0.55)) {
                                timerShakeOffset = 0
                            }
                        }
                    } else {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) { quizIsLocked = true }
                        quizCountdown = 5
                    }
                } else if !mockInteractionShowsResult {
                    // Hold phase
                    if quizCountdown > 0 {
                        quizCountdown -= 1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
                    } else {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        let correct = mockInteractionSelection.map { l in
                            Self.kbcQuizOptions.first(where: { $0.letter == l })?.isCorrect ?? false
                        } ?? false
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            mockInteractionShowsResult = true
                            if correct { showQuizConfetti = true }
                        }
                        quizCountdown = 5
                    }
                } else {
                    // Reveal phase
                    if quizCountdown > 0 {
                        quizCountdown -= 1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.3)
                    } else {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                            dismissMockInteraction()
                        }
                    }
                }
            }
            .task(id: viewModel.requestKey) {
                isDescriptionExpanded = false
                dismissMomentSearchOverlay()
                dismissMockInteraction()
                await viewModel.loadIfNeeded()
            }
            .onDisappear {
                engine.release()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                updateKeyboardHeight(from: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    keyboardHeight = 0
                }
            }
        }
        .onReceive(engine.$isReady) { ready in
            withAnimation(.easeInOut(duration: 0.3)) { isVideoReady = ready }
        }
        .demoAlert(isPresented: $showDemoAlert)
    }

    @ViewBuilder
    private func content(width: CGFloat, height: CGFloat, safeAreaTop: CGFloat) -> some View {
        if let detail = viewModel.detail {
            let kind = DetailPresentationKind.resolve(seed: viewModel.seed, detail: detail)
            // For series/season types the series ID is not a valid playable content ID —
            // wait until the first episode is available and use its ID instead.
            let resolvedPlayerContent: QuickplayPlaybackContent? = detail.supportsEpisodes
                ? viewModel.episodes.first?.quickplayPlaybackContent()
                : detail.quickplayPlaybackContent(fallback: viewModel.seed)
            let navBarHeight: CGFloat = 58
            let headerHeight: CGFloat = isVideoReady
                ? safeAreaTop + navBarHeight + width * 9 / 16
                : UIScreen.main.bounds.width * 3 / 2

            ZStack(alignment: .top) {
                Color(hex: "0A0A0A").ignoresSafeArea()

                // Player sits OUTSIDE the ScrollView — it is truly fixed and never moves.
                // VStack with ignoresSafeArea(edges:.top) makes it start at absolute y=0.
                // When showing the poster (not video), content overlaps the image from the bottom.
                // overlapHeight: how far the scroll view is pulled up into the image.
                // gradientHeight: 40% of image height — solid black at bottom, fading to clear.
                let imageHeight: CGFloat  = width * 3 / 2
                let overlapHeight: CGFloat = isVideoReady ? 0 : width * 0.55
                let gradientHeight: CGFloat = isVideoReady ? 0 : imageHeight * 0.58

                VStack(spacing: 0) {
                    if let playerContent = resolvedPlayerContent {
                    DetailInlinePlayerView(
                        engine: engine,
                        content: playerContent,
                        posterURL: detail.imageURL(for: "0-2x3", width: Int(width * 3)),
                        height: headerHeight,
                        safeAreaTop: safeAreaTop,
                        navBarHeight: navBarHeight,
                        onFullscreen: { openFullPlayer(detail: detail) }
                    )
                    .overlay(alignment: .bottom) {
                        if !isVideoReady {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: Color.black.opacity(0.5), location: 0.35),
                                    .init(color: Color.black.opacity(0.85), location: 0.65),
                                    .init(color: Color.black, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: gradientHeight)
                            .allowsHitTesting(false)
                        }
                    }
                } else {
                    // Episodes not yet loaded — show static poster until first episode is ready
                    PosterImageView(
                        url: detail.imageURL(for: "0-2x3", width: Int(width * 3)),
                        size: CGSize(width: width, height: headerHeight),
                        cornerRadius: 0
                    )
                    .frame(height: headerHeight)
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Color.black.opacity(0.5), location: 0.35),
                                .init(color: Color.black.opacity(0.85), location: 0.65),
                                .init(color: Color.black, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: gradientHeight)
                        .allowsHitTesting(false)
                    }
                }

                    ScrollView(.vertical, showsIndicators: false) {
                        scrollableBody(detail, kind: kind, width: width)
                            .padding(.bottom, kind == .sportsInteractive && selectedSportsTab == "Live Feed" ? 110 : 80)
                    }
                    .padding(.top, -overlapHeight)
                }
                .ignoresSafeArea(edges: .top)
                .zIndex(2)

                // Sticky tab row — pins below the card once the original scrolls past the card bottom
                let showStickyTabs = kind != .sportsInteractive && tabRowGlobalY < headerHeight
                if showStickyTabs {
                    VStack(spacing: 0) {
                        tabRow(detail)
                            .padding(.horizontal, 16)
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1)
                    }
                    .background(Color(hex: "0A0A0A"))
                    .frame(maxWidth: .infinity)
                    .padding(.top, headerHeight - safeAreaTop)
                    .zIndex(5)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.15), value: showStickyTabs)
                }

            }
            .onPreferenceChange(DetailTabRowOffsetKey.self) { y in
                tabRowGlobalY = y
            }
        } else if viewModel.isLoading {
            detailLoadingShimmer(width: width)
        } else {
            ErrorView(
                title: AppStrings.Detail.unavailableTitle,
                message: viewModel.errorMessage ?? AppStrings.Storefront.retryMessage,
                onRetry: {
                    Task { await viewModel.load() }
                }
            )
        }
    }

    // Skeleton shimmer that mirrors the real layout — hero block at top, then content rows.
    // Keeps the eye anchored to where actual content will appear instead of floating at y=0.
    private func detailLoadingShimmer(width: CGFloat) -> some View {
        let heroH = heroHeight(for: width)
        return ZStack(alignment: .top) {
            Color(hex: "0A0A0A").ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Hero-sized shimmer block — matches the tall poster area
                ShimmerView()
                    .frame(width: width, height: heroH)

                // Content shimmer — below the hero, same vertical start as regular detailContent
                VStack(alignment: .leading, spacing: 14) {
                    // Title shimmer
                    ShimmerView()
                        .frame(height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    ShimmerView()
                        .frame(width: width * 0.55, height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    // Meta line shimmer
                    ShimmerView()
                        .frame(width: width * 0.4, height: 14)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                    // Watch button shimmer
                    ShimmerView()
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    // Description shimmer lines
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach([1.0, 0.88, 0.72] as [CGFloat], id: \.self) { fraction in
                            ShimmerView()
                                .frame(width: width * fraction, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 28)
            }
        }
    }

    private func hero(_ detail: ContentDetail, width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            PosterImageView(
                url: detail.imageURL(for: "0-16x9", width: Int(width * 3)),
                size: CGSize(width: width, height: heroHeight(for: width)),
                cornerRadius: 0
            )

            LinearGradient(
                colors: [
                    Color(hex: "0A0A0A").opacity(0.8),
                    Color(hex: "0A0A0A").opacity(0.35),
                    Color(hex: "0A0A0A").opacity(0),
                    Color(hex: "0A0A0A").opacity(0.36),
                    Color(hex: "0A0A0A")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: width, height: heroHeight(for: width))
        .clipped()
    }

    private func heroHeight(for width: CGFloat) -> CGFloat {
        width/16 * 9
    }

    private var miniHeroHeight: CGFloat { 220 }

    private func scrollableBody(_ detail: ContentDetail, kind: DetailPresentationKind, width: CGFloat) -> some View {
        Group {
            if kind == .sportsInteractive {
                sportsScrollContent(detail, width: width)
            } else {
                entertainmentScrollContent(detail, kind: kind, width: width)
            }
        }
    }

    // AnyView erasure is intentional — these functions compose multiple opaque `some View`
    // returns from separate helpers into a single VStack, producing a generic type too deep
    // for Swift's runtime TypeDecoder. Erasure at this boundary keeps the type flat.
    private func sportsScrollContent(_ detail: ContentDetail, width: CGFloat) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 0) {
                sportsAboveTabContent(detail, width: width)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                VStack(spacing: 0) {
                    sportsTabRow
                        .padding(.horizontal, 16)
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                }
                sportsTabContent(detail, width: width)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            }
        )
    }

    private func entertainmentScrollContent(_ detail: ContentDetail, kind: DetailPresentationKind, width: CGFloat) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 0) {
                detailContent(detail, kind: kind, width: width)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                VStack(spacing: 0) {
                    tabRow(detail)
                        .padding(.horizontal, 16)
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: DetailTabRowOffsetKey.self,
                            value: geo.frame(in: .global).minY
                        )
                    }
                )
                tabContent(detail, width: width)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }
        )
    }

    private func detailContent(_ detail: ContentDetail, kind: DetailPresentationKind, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(detail.title)
                .font(.system(size: 28, weight: .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FFF75A"), Color(hex: "F5A623")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            metaLine(detail)
            watchButton(detail, kind: kind)
            descriptionBlock(detail)
            actionButtonRow(detail, kind: kind)
            sponsorRow(detail)
        }
    }

    private func titleArt(_ detail: ContentDetail) -> some View {
        Text(detail.title.uppercased())
            .font(.system(size: 41, weight: .black, design: .rounded))
            .tracking(-1.5)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.58)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "FFF75A"), Color(hex: "F5A623"), Color.white],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: Color.black.opacity(0.55), radius: 8, x: 0, y: 3)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 78)
            .padding(.bottom, 8)
    }

    private func metaLine(_ detail: ContentDetail) -> some View {
        // Prefer detail's own fields; fall back to seed when detail API omits them.
        let year    = detail.year ?? viewModel.seed?.year
        let genres  = detail.genres.isEmpty ? (viewModel.seed?.genres ?? []) : detail.genres
        let runtime = detail.runtimeSeconds ?? viewModel.seed?.runtimeSeconds
        let runtimeText = runtime.map(ContentDetail.formatRuntime(seconds:))
        let parts   = [year, genres.prefix(3).joined(separator: " · ").nilIfEmpty, runtimeText].compactMap { $0 }
        let text    = parts.joined(separator: " · ").uppercased()

        return Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.white)
            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openFullPlayer(detail: ContentDetail) {
        onPlay(detail, viewModel.seed)
    }

    private func watchButton(_ detail: ContentDetail, kind: DetailPresentationKind) -> some View {
        Button {
            openFullPlayer(detail: detail)
        } label: {
            Text(watchTitle(for: detail, kind: kind))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "1E1E1E"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(LiquidGlassBackground(cornerRadius: 10, tone: .light, isHighlighted: true))
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private func watchTitle(for detail: ContentDetail, kind: DetailPresentationKind) -> String {
        if viewModel.seed?.progress != nil {
            return "Resume"
        }

        switch kind {
        case .sportsInteractive:
            return "Watch Live"
        case .showInteractive:
            return detail.contentType.lowercased().contains("episode") ? "Watch Episode" : "Watch Show"
        case .regular:
            return AppStrings.Detail.watchNow
        }
    }

    // MARK: - Sports Detail

    // Title + action buttons only — the tab bar is a separate pinned Section header
    private func sportsAboveTabContent(_ detail: ContentDetail, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(detail.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(detail.description.nilIfEmpty ?? "India vs Sri Lanka • ICC T20 World Cup • Live")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
            }

            // 3 action buttons: alert | time stamp | AI sparkles
            HStack(spacing: 8) {
                DetailActionButton(systemImage: "bell.fill", cornerStyle: .leading, action: { showDemoAlert = true })
                DetailActionButton(systemImage: "list.bullet.rectangle") {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                        isTimeStampPresented = true
                    }
                }
                DetailActionButton(systemImage: AppIcons.Action.sparkles, cornerStyle: .trailing, isHighlighted: true) {
                    presentMomentSearchOverlay(for: detail)
                }
            }
            .padding(.top, 14)
        }
    }

    private var sportsTabRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(["Live Feed", "Scorecard", "Key Moments", "You May also Like"], id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedSportsTab = tab
                        }
                    } label: {
                        VStack(spacing: 12) {
                            Text(tab)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(selectedSportsTab == tab ? .white : .white.opacity(0.44))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)

                            Rectangle()
                                .fill(selectedSportsTab == tab ? Color.white : Color.clear)
                                .frame(height: 2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func sportsTabContent(_ detail: ContentDetail, width: CGFloat) -> some View {
        switch selectedSportsTab {
        case "Live Feed":
            sportsLiveFeedTab
        case "Scorecard":
            sportsScorecardTab
        case "Key Moments":
            momentsSection(detail)
        default:
            recommendationSection(width: width)
        }
    }

    // MARK: Live Feed tab

    private var sportsLiveFeedTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sportsLiveChatMessages) { msg in
                liveChatRow(msg)
            }

            sportsPollInChat
                .padding(.top, 8)

            ForEach(liveChatDemoMessages) { msg in
                liveChatRow(msg)
            }
        }
        .padding(.top, 10)
    }

    private func sendLiveChatMessage() {
        let text = liveChatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let newMsg = SportsLiveChatMessage(
            id: UUID().uuidString,
            username: "You",
            text: text,
            avatarLetter: "Y",
            colorHex: "6366F1"
        )
        withAnimation(.easeInOut(duration: 0.18)) {
            liveChatDemoMessages.append(newMsg)
            liveChatInput = ""
        }
    }

    // Live Feed input dock — floats above keyboard in the outer ZStack
    private var sportsLiveInputDock: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            // Emoji bar
            HStack(spacing: 0) {
                ForEach(["😅", "😮", "😤", "💀", "👏", "❤️", "🤍", "😂"], id: \.self) { emoji in
                    Button {
                        showDemoAlert = true
                    } label: {
                        Text(emoji)
                            .font(.system(size: 22))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
            }
            .padding(.horizontal, 4)

            // Send message input
            HStack(spacing: 0) {
                TextField("", text: $liveChatInput, prompt: Text("Send message").foregroundStyle(.white.opacity(0.38)))
                    .focused($isChatInputFocused)
                    .submitLabel(.send)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                    .padding(.leading, 18)
                    .frame(height: 54)
                    .onSubmit { sendLiveChatMessage() }

                Button(action: { showDemoAlert = true }) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.52))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(LiquidButtonPressStyle())

                // Rounded send button inside the field
                Button(action: sendLiveChatMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(liveChatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.25) : Color.white)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(liveChatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                      ? Color.white.opacity(0.1)
                                      : Color(hex: "6366F1"))
                        )
                }
                .buttonStyle(LiquidButtonPressStyle())
                .disabled(liveChatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.trailing, 10)
                .animation(.easeInOut(duration: 0.15), value: liveChatInput)
            }
            .background(
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 27, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color(hex: "0A0A0A").opacity(0.96).ignoresSafeArea(edges: .bottom))
    }

    private func liveChatRow(_ msg: SportsLiveChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color(hex: msg.colorHex))
                .frame(width: 34, height: 34)
                .overlay(
                    Text(msg.avatarLetter)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(msg.username)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.46))

                Text(msg.text)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 7)
    }

    private var sportsPollInChat: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "FFD166"))
                Text("Quick Poll")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "FFD166"))
            }

            Text("Will S Gill hit a six in next over?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                sportsPollButton("Yes", fillColor: Color(hex: "22C55E"), percent: "68%")
                sportsPollButton("No", fillColor: Color(hex: "EF4444"), percent: "32%")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(hex: "FFD166").opacity(0.32), lineWidth: 1)
                )
        )
    }

    private func sportsPollButton(_ title: String, fillColor: Color, percent: String) -> some View {
        let isSelected = sportsPollAnswer == title
        let isLocked = sportsPollAnswer != nil

        return Button {
            guard !isLocked else { return }
            withAnimation(.easeInOut(duration: 0.2)) { sportsPollAnswer = title }
        } label: {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(fillColor)
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)

                Spacer(minLength: 0)

                if isLocked {
                    Text(percent)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? fillColor.opacity(0.22) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? fillColor.opacity(0.72) : Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .disabled(isLocked)
        .buttonStyle(LiquidButtonPressStyle())
    }

    // MARK: Key Moments tab

    private struct KeyMoment: Identifiable {
        let id: String
        let title: String
        let caption: String
    }

    private let sportsKeyMoments: [KeyMoment] = [
        .init(id: "1", title: "Six Of The Day",          caption: "S Gill hits a massive six"),
        .init(id: "2", title: "75 Meter Six",             caption: "Jaw-dropping hit by S Gill"),
        .init(id: "3", title: "Bumrah's Wicket",          caption: "D Wellalage caught behind"),
        .init(id: "4", title: "Rohit Fifty",              caption: "Captain's knock in 42 balls"),
    ]

    private func sportsKeyMomentsTab(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Featured moment chip
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                    isTimeStampPresented = true
                }
            } label: {
                HStack(spacing: 10) {
                    Text("S Gill six")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer(minLength: 0)
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(hex: "A855F7"), Color(hex: "7C3AED")],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(hex: "A855F7").opacity(0.4), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(LiquidButtonPressStyle())
            .padding(.top, 8)

            // Full-width video moment cards
            ForEach(sportsKeyMoments) { moment in
                keyMomentCard(moment, width: width)
            }
        }
        .padding(.bottom, 20)
    }

    private func keyMomentCard(_ moment: KeyMoment, width: CGFloat) -> some View {
        let cardHeight = (width - 32) * 9 / 16
        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "1A1A2E"))

            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Play button
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.88))
                    .frame(width: 48, height: 48)
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(moment.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(moment.caption)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(12)
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: Time Stamp overlay (node 18-60305)

    private struct TimeStampItem: Identifiable {
        let id: String
        let title: String
        let time: String
    }

    private let timeStampItems: [TimeStampItem] = [
        .init(id: "1", title: "Virat Hits 4",                    time: "2:30"),
        .init(id: "2", title: "Vaiabhav suriyavanshi hits 6",    time: "4:50"),
        .init(id: "3", title: "Rohit Sharma scores a boundary",  time: "5:30"),
        .init(id: "4", title: "Kohli takes a six",               time: "6:00"),
        .init(id: "5", title: "Virat took 2 runs",               time: "7:15"),
    ]

    private var timeStampOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // Header
                HStack {
                    Text("Time Stamp")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                            isTimeStampPresented = false
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Moment list
                ForEach(timeStampItems) { item in
                    timeStampRow(item)
                    if item.id != timeStampItems.last?.id {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(hex: "111111"))
                    .ignoresSafeArea(edges: .bottom)
            )
            .onTapGesture { } // block tap-through
        }
        .background(
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                        isTimeStampPresented = false
                    }
                }
        )
    }

    private func timeStampRow(_ item: TimeStampItem) -> some View {
        HStack(spacing: 14) {
            // Thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "1A2A3A"))
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(width: 100, height: 70)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Time badge
                Text(item.time)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(hex: "0EA5E9"))
                    )
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { showDemoAlert = true }
    }

    // MARK: Scorecard tab

    private var sportsScorecardTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            scorecardScoreBlock.padding(.top, 14)
            scorecardLiveMatchRow.padding(.top, 12)
            scorecardInningsTabRow.padding(.top, 16)
            sportsBattingTable.padding(.top, 12)
            sportsBowlingTable.padding(.top, 16)
            scorecardTopPerformance.padding(.top, 16)
            scorecardFallOfWickets.padding(.top, 16)
            scorecardPartnership.padding(.top, 16).padding(.bottom, 20)
        }
    }

    private var scorecardScoreBlock: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 0) {
                // Left team — IND
                HStack(alignment: .center, spacing: 10) {
                    // India team badge
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "1A3A6B"), Color(hex: "0D2040")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Color(hex: "6B8FC9").opacity(0.5), lineWidth: 1))
                        Text("🇮🇳")
                            .font(.system(size: 22))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("IND")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                        Text("210-5")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        HStack(spacing: 4) {
                            Circle().fill(Color(hex: "22C55E")).frame(width: 6, height: 6)
                            Text("Over 20")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.52))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right team — SL
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("SL")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                        Text("48-2")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        HStack(spacing: 4) {
                            Image(systemName: "cricket.ball.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: "D4A017"))
                            Text("Over 5.4")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.52))
                        }
                    }
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "1A4A2E"), Color(hex: "0D2518")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Color(hex: "5DAD6B").opacity(0.5), lineWidth: 1))
                        Text("🇱🇰")
                            .font(.system(size: 22))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)

            // LIVE badge — top right
            HStack(spacing: 4) {
                Circle().fill(Color(hex: "E50914")).frame(width: 6, height: 6)
                Text("Live")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Capsule().fill(Color(hex: "E50914").opacity(0.18)))
            .overlay(Capsule().stroke(Color(hex: "E50914").opacity(0.5), lineWidth: 1))
            .padding(.top, 10)
            .padding(.trailing, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "0D1C2E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var scorecardLiveMatchRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Bowler info
            HStack(spacing: 12) {
                Image(systemName: "cricket.ball.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "72F6A2"))

                VStack(alignment: .leading, spacing: 1) {
                    Text("J Bumrah")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text("3.5 - 8 - 1")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.52))
                }

                Spacer()

                // Ball history
                HStack(spacing: 4) {
                    ForEach([("W", "E50914", false), ("0", "", true), ("4", "22C55E", false), ("1LB", "", true)], id: \.0) { ball, colorHex, isLight in
                        Text(ball)
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(isLight ? Color.white.opacity(0.82) : Color.white)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle().fill(
                                    isLight ? Color.white.opacity(0.12) : Color(hex: colorHex)
                                )
                            )
                    }
                }
            }

            // At-crease batters
            HStack(spacing: 16) {
                batsmanChip(name: "D Warner", scoreStr: "0  1")
                batsmanChip(name: "G Maxwell", scoreStr: "52  38")
            }
        }
        .padding(14)
        .background(LiquidGlassBackground(cornerRadius: 14, tone: .dark))
    }

    private func batsmanChip(name: String, scoreStr: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.62))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(scoreStr)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.52))
            }
        }
    }

    private var scorecardInningsTabRow: some View {
        HStack(spacing: 8) {
            ForEach(["India", "Sri Lanka"], id: \.self) { team in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        scorecardTeamTab = team
                    }
                } label: {
                    Text(team)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(scorecardTeamTab == team ? Color(hex: "0A0A0A") : .white.opacity(0.62))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(scorecardTeamTab == team ? Color.white : Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
        }
    }

    private var sportsBattingTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("Batter")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("R").frame(width: 34, alignment: .trailing)
                Text("B").frame(width: 30, alignment: .trailing)
                Text("4s").frame(width: 28, alignment: .trailing)
                Text("6s").frame(width: 28, alignment: .trailing)
                Text("SR").frame(width: 48, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white.opacity(0.44))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)

            ForEach(scorecardInnningsData) { batter in
                sportsBatterRow(batter)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            }

            // Extras row
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Extras")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.82))
                    HStack(spacing: 5) {
                        ForEach(["LB 1", "W 21"], id: \.self) { chip in
                            Text(chip)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white.opacity(0.72))
                                .padding(.horizontal, 6)
                                .frame(height: 16)
                                .background(Capsule().fill(Color.white.opacity(0.12)))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("21").frame(width: 34, alignment: .trailing)
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                Spacer().frame(width: 30 + 28 + 28 + 48)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .background(LiquidGlassBackground(cornerRadius: 14, tone: .dark))
    }

    private var sportsBowlingTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("Bowler").frame(maxWidth: .infinity, alignment: .leading)
                Text("O").frame(width: 34, alignment: .trailing)
                Text("M").frame(width: 26, alignment: .trailing)
                Text("R").frame(width: 30, alignment: .trailing)
                Text("W").frame(width: 28, alignment: .trailing)
                Text("ER").frame(width: 44, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white.opacity(0.44))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)

            ForEach(scorecardBowlingData) { bowler in
                HStack(spacing: 0) {
                    Text(bowler.name)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(bowler.o).frame(width: 34, alignment: .trailing)
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                    Text(bowler.m).frame(width: 26, alignment: .trailing)
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.52))
                    Text(bowler.r).frame(width: 30, alignment: .trailing)
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.52))
                    Text(bowler.w).frame(width: 28, alignment: .trailing)
                        .font(.system(size: 12, weight: bowler.w != "0" ? .bold : .regular))
                        .foregroundStyle(bowler.w != "0" ? Color(hex: "22C55E") : .white.opacity(0.52))
                    Text(bowler.er).frame(width: 44, alignment: .trailing)
                        .font(.system(size: 11)).foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                if bowler.id != scorecardBowlingData.last?.id {
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                }
            }
        }
        .background(LiquidGlassBackground(cornerRadius: 14, tone: .dark))
    }

    private var scorecardTopPerformance: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Performance")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    scorecardPerfCard(mainStat: "80", subStat: "40", label: "S Gill",       sub: "Runs")
                    scorecardPerfCard(mainStat: "90", subStat: "48", label: "V Kohli",      sub: "Runs")
                    scorecardPerfCard(mainStat: "5-40", subStat: "3.4", label: "V Kohli",   sub: "Bowling")
                    scorecardPerfCard(mainStat: "4-18", subStat: "4.0", label: "C Asalanka",sub: "Bowling")
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func scorecardPerfCard(mainStat: String, subStat: String, label: String, sub: String) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(mainStat)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(subStat)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.55))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(sub)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.44))
        }
        .frame(width: 92)
        .padding(.vertical, 14)
        .background(LiquidGlassBackground(cornerRadius: 12, tone: .dark))
    }

    private var scorecardFallOfWickets: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("Fall of Wickets").frame(maxWidth: .infinity, alignment: .leading)
                Text("Score").frame(width: 60, alignment: .trailing)
                Text("Over").frame(width: 48, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white.opacity(0.44))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)

            ForEach([
                ("R Sharma (c)", "39-1",  "4.1"),
                ("S Gill",       "88-2",  "7.6"),
                ("V Kohli",      "119-3", "10.2"),
            ], id: \.0) { name, score, over in
                HStack(spacing: 0) {
                    Text(name).font(.system(size: 13)).foregroundStyle(.white.opacity(0.82))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(score).frame(width: 60, alignment: .trailing)
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                    Text(over).frame(width: 48, alignment: .trailing)
                        .font(.system(size: 12)).foregroundStyle(.white.opacity(0.52))
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
            }
        }
        .background(LiquidGlassBackground(cornerRadius: 14, tone: .dark))
    }

    private var scorecardPartnership: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Partnership")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))

            VStack(spacing: 10) {
                partnershipRow(p1Name: "R Sharma", p1Runs: 47, p1Balls: 42, p2Name: "S Gill",    p2Runs: 19, p2Balls: 25)
                partnershipRow(p1Name: "R Sharma", p1Runs: 5,  p1Balls: 4,  p2Name: "V Kohli",   p2Runs: 3,  p2Balls: 12)
                partnershipRow(p1Name: "R Sharma", p1Runs: 1,  p1Balls: 2,  p2Name: "I Kishan",  p2Runs: 0,  p2Balls: 6)
                partnershipRow(p1Name: "I Kishan", p1Runs: 23, p1Balls: 45, p2Name: "KL Rahul",  p2Runs: 39, p2Balls: 44)
            }
        }
        .padding(14)
        .background(LiquidGlassBackground(cornerRadius: 14, tone: .dark))
    }

    private func partnershipRow(p1Name: String, p1Runs: Int, p1Balls: Int, p2Name: String, p2Runs: Int, p2Balls: Int) -> some View {
        let total = p1Runs + p2Runs
        let p1Frac = total > 0 ? CGFloat(p1Runs) / CGFloat(total) : 0.5
        let p2Frac = total > 0 ? CGFloat(p2Runs) / CGFloat(total) : 0.5

        return VStack(spacing: 4) {
            HStack(spacing: 6) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(p1Name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.82))
                    Text("\(p1Runs) \(p1Balls)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.44))
                }
                .frame(width: 76, alignment: .trailing)
                .lineLimit(1).minimumScaleFactor(0.8)

                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "6366F1"))
                            .frame(width: max(4, geo.size.width * p1Frac))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "F59E0B"))
                            .frame(width: max(4, geo.size.width * p2Frac))
                    }
                }
                .frame(height: 8)

                VStack(alignment: .leading, spacing: 1) {
                    Text(p2Name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.82))
                    Text("\(p2Runs) \(p2Balls)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.44))
                }
                .frame(width: 76, alignment: .leading)
                .lineLimit(1).minimumScaleFactor(0.8)
            }
        }
    }

    private func sportsBatterRow(_ batter: ScorecardBatter) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(batter.name)
                        .font(.system(size: 13, weight: batter.isAtCrease ? .bold : .regular))
                        .foregroundStyle(batter.isAtCrease ? .white : .white.opacity(0.82))
                        .lineLimit(1)

                    if batter.isAtCrease {
                        Circle()
                            .fill(Color(hex: "22C55E"))
                            .frame(width: 6, height: 6)
                    }
                }

                Text(batter.dismissal)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.white.opacity(0.34))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(batter.r).frame(width: 34, alignment: .trailing)
                .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
            Text(batter.b).frame(width: 30, alignment: .trailing)
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.52))
            Text(batter.fours).frame(width: 28, alignment: .trailing)
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.52))
            Text(batter.sixes).frame(width: 28, alignment: .trailing)
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.52))
            Text(batter.sr).frame(width: 48, alignment: .trailing)
                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private func descriptionBlock(_ detail: ContentDetail) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(detail.description)
                .font(.system(size: 14, weight: .regular))
                .lineSpacing(2)
                .foregroundStyle(Color(hex: "FEFEFE"))
                .lineLimit(isDescriptionExpanded ? nil : 2)
                .animation(.easeInOut(duration: 0.2), value: isDescriptionExpanded)

            if detail.description.count > 88 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDescriptionExpanded.toggle()
                    }
                } label: {
                    Text(isDescriptionExpanded ? "View Less" : "View More")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
        }
    }

    @ViewBuilder
    private func previewLabel(_ detail: ContentDetail) -> some View {
        if detail.hasFreePreview || detail.previewURL != nil {
            Text("Free preview Available ( 10 mins)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "F5A623"))
                .lineLimit(1)
        }
    }

    private func actionButtonRow(_ detail: ContentDetail, kind: DetailPresentationKind) -> some View {
        HStack(spacing: 8) {
            DetailActionButton(assetImage: "clapperboard", cornerStyle: .leading, action: { showDemoAlert = true })
            DetailActionButton(assetImage: "download", action: { showDemoAlert = true })
            // Favourite toggle — bookmark-plus asset when not saved, SF bookmark.fill when saved
            if viewModel.isFavorite {
                DetailActionButton(systemImage: "bookmark.fill", isHighlighted: true) {
                    Task { await viewModel.toggleFavorite() }
                }
            } else {
                DetailActionButton(assetImage: "bookmark-plus") {
                    Task { await viewModel.toggleFavorite() }
                }
            }
            // Like / Dislike — cycles: none → liked → disliked → none
            switch viewModel.likeState {
            case .liked:
                DetailActionButton(systemImage: "hand.thumbsup.fill", isHighlighted: true) {
                    Task { await viewModel.cycleLike() }
                }
            case .disliked:
                DetailActionButton(systemImage: "hand.thumbsdown.fill", isHighlighted: true) {
                    Task { await viewModel.cycleLike() }
                }
            case .none:
                DetailActionButton(assetImage: "thumbs-up-down") {
                    Task { await viewModel.cycleLike() }
                }
            }
            DetailActionButton(assetImage: "share", iconSize: 22, action: { showDemoAlert = true })
            DetailActionButton(systemImage: AppIcons.Action.sparkles, cornerStyle: .trailing, isHighlighted: true) {
                presentMomentSearchOverlay(for: detail)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.detail?.momentSearchEnabled == true {
                searchMomentsPill
                    .offset(x: 34, y: 36)
            }
        }
    }

    private var searchMomentsPill: some View {
        HStack(spacing: 4) {
            Image(systemName: AppIcons.Action.sparkles)
                .font(.system(size: 13, weight: .bold))
            Text("Search Moments")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Color(hex: "202020"))
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 4)
        )
        .allowsHitTesting(false)
    }

    private func sponsorRow(_ detail: ContentDetail) -> some View {
        HStack(spacing: 5) {
            Text("SPONSORED BY")
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.78))
            Text(detail.sponsorNames.first ?? "KFC")
                .font(.system(size: 15, weight: .black))
                .italic()
                .foregroundStyle(.white)
        }
        .frame(height: 30)
    }

    private func detailTabs(for detail: ContentDetail) -> [String] {
        if detail.supportsEpisodes {
            return [
                AppStrings.Detail.episodes,
                AppStrings.Detail.moreLikeThis,
                AppStrings.Detail.moments,
                AppStrings.Detail.castAndMore
            ]
        }

        return [
            AppStrings.Detail.moreLikeThis,
            AppStrings.Detail.moments,
            AppStrings.Detail.castAndMore
        ]
    }

    private func tabRow(_ detail: ContentDetail) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(detailTabs(for: detail), id: \.self) { tab in
                    Button {
                        selectTab(tab, detail: detail)
                    } label: {
                        VStack(spacing: 13) {
                            Text(tab)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)

                            Rectangle()
                                .fill(viewModel.selectedTab == tab ? Color.white : Color.clear)
                                .frame(height: 1)
                        }
                        .frame(minWidth: tab == AppStrings.Detail.moreLikeThis ? 118 : 92)
                        .padding(.horizontal, 6)
                        .padding(.top, 14)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func tabContent(_ detail: ContentDetail, width: CGFloat) -> some View {
        switch viewModel.selectedTab {
        case AppStrings.Detail.moreLikeThis:
            recommendationSection(width: width)
        case AppStrings.Detail.moments:
            momentsSection(detail)
        case AppStrings.Detail.episodes:
            episodesSection(width: width)
        default:
            castSection(detail)
        }
    }

    private func recommendationSection(width: CGFloat) -> some View {
        let cardWidth = max(96, (width - 40) / 3)
        let cardHeight = cardWidth * 1.5
        let visibleItems = Array(viewModel.recommendations.prefix(6))
        let featuredItem = Array(viewModel.recommendations.dropFirst(6)).first ?? viewModel.recommendations.first

        return VStack(spacing: 4) {
            if viewModel.recommendations.isEmpty {
                EmptyStateView(title: AppStrings.Detail.moreLikeThis, message: AppStrings.Detail.noRecommendations, systemImage: AppIcons.Action.film)
                    .padding(.top, 18)
            } else {
                LazyVGrid(columns: recommendationColumns, spacing: 4) {
                    ForEach(visibleItems) { item in
                        DetailRecommendationCard(
                            item: item,
                            size: CGSize(width: cardWidth, height: cardHeight),
                            onSelect: onSelectRecommendation
                        )
                    }
                }

                if let featuredItem {
                    Button {
                        onSelectRecommendation(featuredItem)
                    } label: {
                        DetailFeaturedRecommendationCard(item: featuredItem, width: width - 32)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
            }
        }
    }

    private func momentsSection(_ detail: ContentDetail) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            if detail.momentSearchEnabled {
                Text("Explore related moments")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 4)

                momentResultsContent
            } else {
                Text(AppStrings.Detail.notAvailable)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(UIConstants.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LiquidGlassBackground(cornerRadius: UIConstants.CornerRadius.lg, tone: .dark))
            }
        }
        .padding(.top, 8)
    }

    private func selectTab(_ tab: String, detail: ContentDetail) {
        viewModel.selectTab(tab)
        guard tab == AppStrings.Detail.moments,
              detail.momentSearchEnabled,
              viewModel.momentResults.isEmpty,
              viewModel.momentQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        viewModel.submitMomentSearch(detail.title)
    }

    private func presentMomentSearchOverlay(for detail: ContentDetail) {
        guard detail.momentSearchEnabled else { return }
        viewModel.selectTab(AppStrings.Detail.moments)
        momentSearchDraft = viewModel.momentResults.isEmpty ? viewModel.momentQuery : ""

        withAnimation(.easeInOut(duration: 0.26)) {
            isMomentSearchOverlayPresented = true
        }

        // Focus immediately so keyboard and search bar move up together in one motion.
        // Using a minimal delay only for the focus state to settle after the overlay appears.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isMomentSearchFocused = true
        }
    }

    private func dismissMomentSearchOverlay() {
        isMomentSearchFocused = false
        withAnimation(.easeInOut(duration: 0.24)) {
            isMomentSearchOverlayPresented = false
        }
    }

    private func presentMockInteraction() {
        quizIsLocked = false
        quizCountdown = 20
        mockInteractionSelection = nil
        mockInteractionShowsResult = false
        showQuizConfetti = false
        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
            isMockInteractionPresented = true
        }
    }

    private func dismissMockInteraction() {
        isMockInteractionPresented = false
        quizIsLocked = false
        quizCountdown = 20
        mockInteractionSelection = nil
        mockInteractionShowsResult = false
        showQuizConfetti = false
    }

    private func answerMockInteraction(_ letter: String) {
        guard !quizIsLocked else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.75)
        withAnimation(.easeInOut(duration: 0.18)) {
            mockInteractionSelection = letter
            // Timer keeps running — user can still change answer until countdown hits 0
        }
    }


    // MARK: KBC Quiz overlay (full screen)

    // MARK: - KBC Quiz panel (inline, replaces detailContent)

    private static let kbcQuizOptions: [(letter: String, text: String, isCorrect: Bool)] = [
        ("A", "18", true),
        ("B", "10", false),
        ("C", "12", false),
        ("D", "4",  false)
    ]

    private func quizOverlay(detail: ContentDetail, width: CGFloat) -> some View {
        let hexW: CGFloat = width * 0.693

        return ZStack {
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "2602A2"), location: 0),
                        .init(color: Color(hex: "1E0535"), location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                Color.black.opacity(0.77)
            }
            .ignoresSafeArea(edges: .bottom)

            if showQuizConfetti {
                KBCConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(99)
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Countdown circle — standalone, centered (Figma: sits just below the video)
                    kbcCountdownCircle
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                        .padding(.bottom, 10)

                    Text("How many holes are contained in a typical golf course")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(width: width * 0.823)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        stops: [.init(color: Color(hex: "000001"), location: 0.028),
                                                .init(color: Color(hex: "00083A"), location: 0.993)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.7), radius: 45, x: 0, y: 0)
                        )

                    VStack(spacing: 15) {
                        ForEach(Self.kbcQuizOptions, id: \.letter) { opt in
                            kbcOptionRow(opt.letter, text: opt.text, isCorrect: opt.isCorrect,
                                         screenWidth: width, hexW: hexW)
                        }
                    }
                    .padding(.top, 22)

                    kbcLifelineRow
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ── Quiz nav bar overlay (Figma 18-56986): back | crown+score | game-controller ──
    private func quizNavBarOverlay(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: safeAreaTop)
            HStack(spacing: 0) {
                Button { dismissMockInteraction() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 45, height: 45)
                        .background(.black.opacity(0.23), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1.2))
                }
                .buttonStyle(LiquidButtonPressStyle())

                Spacer()

                HStack(spacing: 10) {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(hex: "FFA576"))
                            .frame(width: 30, height: 30)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "FFAC33"), lineWidth: 1))
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Color(hex: "FFAC33"))
                            .rotationEffect(.degrees(-35))
                            .offset(x: -6, y: -7)
                    }
                    .frame(width: 30, height: 30)

                    Text("1300")
                        .font(.system(size: 26, weight: .bold))
                        .italic()
                        .foregroundStyle(Color(hex: "FFAC33"))
                }

                Spacer()

                Button {} label: {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .frame(width: 45, height: 45)
                        .background(.black.opacity(0.23), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1.2))
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
            .frame(height: 58)
            .padding(.horizontal, 16)
        }
    }

    // ── Animated countdown circle ──────────────────────────────────────────
    // Phase 1 (answer, !quizIsLocked): arc 20→0, orange→red number.
    // Phase 2 (hold,   quizIsLocked && !showsResult): lock icon, white arc draining 5→0.
    // Phase 3 (reveal, showsResult): hidden — results speak for themselves.
    private var kbcCountdownCircle: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "260299").opacity(0.55))
                .frame(width: 52, height: 52)
                .blur(radius: 12)

            Circle()
                .fill(Color(hex: "080A22"))
                .frame(width: 52, height: 52)
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))

            if mockInteractionShowsResult {
                // Reveal phase — blank circle, no arc
                EmptyView()
            } else if quizIsLocked {
                // Hold phase — white draining arc + lock icon
                Circle()
                    .trim(from: 0, to: CGFloat(quizCountdown) / 5.0)
                    .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 46, height: 46)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: quizCountdown)

                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                // Answer phase — orange/red arc + countdown number
                Circle()
                    .trim(from: 0, to: CGFloat(quizCountdown) / 20.0)
                    .stroke(
                        quizCountdown > 5 ? Color(hex: "FFAC33") : Color(hex: "FF3B30"),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 46, height: 46)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: quizCountdown)

                // New identity each second → transition fires a pop-scale animation
                Text("\(quizCountdown)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(quizCountdown > 5 ? .white : Color(hex: "FF3B30"))
                    .id(quizCountdown)
                    .offset(y: timerShakeOffset)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 1.5).combined(with: .opacity),
                            removal: .scale(scale: 0.6).combined(with: .opacity)
                        )
                    )
                    .animation(.spring(response: 0.28, dampingFraction: 0.62), value: quizCountdown)
            }
        }
        .frame(width: 52, height: 52)
    }

    // ── Single option row ─────────────────────────────────────────────────
    private func kbcOptionRow(_ letter: String, text: String, isCorrect: Bool,
                               screenWidth: CGFloat, hexW: CGFloat) -> some View {
        let isSelected = mockInteractionSelection == letter
        let isLocked   = quizIsLocked   // true when timer expires OR user taps
        let showResult = mockInteractionShowsResult

        let hexFill: Color = {
            if showResult {
                if isCorrect { return Color(hex: "22C55E") }
                if isSelected { return Color(hex: "EF4444") }
            } else if isSelected {
                // Keep the selection highlight through the hold phase
                return Color(hex: "E48820")
            }
            return Color(hex: "000001").opacity(0.95)
        }()

        let hexStroke: Color = {
            if showResult && isCorrect  { return Color(hex: "22C55E") }
            if showResult && isSelected { return Color(hex: "EF4444") }
            if isSelected { return Color(hex: "E48820") }
            return Color.white.opacity(0.25)
        }()

        let letterColor: Color = {
            if (showResult || isLocked) && (isCorrect || isSelected) { return .white }
            if isSelected { return .white }
            if isLocked   { return Color(hex: "E48820").opacity(0.35) }
            return Color(hex: "E48820")
        }()

        let textAlpha: Double = isLocked && !isSelected && !(showResult && isCorrect) ? 0.35 : 1.0

        return Button { answerMockInteraction(letter) } label: {
            ZStack {
                // Full-width horizontal line (Figma imgLine1 effect)
                Rectangle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: screenWidth, height: 1)

                // Hex shape centred
                ZStack {
                    KBCHexShape().fill(hexFill).frame(width: hexW, height: 43)
                    KBCHexShape().stroke(hexStroke, lineWidth: 1).frame(width: hexW, height: 43)

                    HStack(spacing: 0) {
                        Text(letter + ".")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(letterColor)
                            .frame(width: hexW * 0.27)

                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 1, height: 22)

                        Text(text)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(textAlpha))
                            .frame(maxWidth: .infinity)
                    }
                    .frame(width: hexW * 0.9)
                }
            }
            .frame(width: screenWidth, height: 43)
        }
        .disabled(isLocked || showResult)
        .buttonStyle(LiquidButtonPressStyle())
        .animation(.easeInOut(duration: 0.2), value: mockInteractionSelection)
        .animation(.easeInOut(duration: 0.2), value: mockInteractionShowsResult)
    }

    // ── Lifelines row ─────────────────────────────────────────────────────
    private var kbcLifelineRow: some View {
        HStack(spacing: 8) {
            kbcLifelineBtn(label: "50:50",  icon: nil)
            kbcLifelineBtn(label: nil,      icon: "arrow.clockwise")
            kbcLifelineBtn(label: nil,      icon: "person.fill")
            kbcLifelineBtn(label: nil,      icon: "chart.bar.fill")
        }
    }

    private func kbcLifelineBtn(label: String?, icon: String?) -> some View {
        Button {} label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            stops: [.init(color: Color(hex: "000001"), location: 0.052),
                                    .init(color: Color(hex: "00083A"), location: 0.994)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))

                if let label { Text(label).font(.system(size: 14, weight: .medium)).foregroundStyle(.white) }
                else if let icon { Image(systemName: icon).font(.system(size: 18)).foregroundStyle(.white) }
            }
            .frame(width: 62, height: 45)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }



    private func submitMomentSearchOverlay() {
        let query = momentSearchDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return }

        dismissMomentSearchOverlay()
        viewModel.submitMomentSearch(query)

        // For sports page: auto-switch to Key Moments tab so scroll lands visibly
        if let detail = viewModel.detail {
            let kind = DetailPresentationKind.resolve(seed: viewModel.seed, detail: detail)
            if kind == .sportsInteractive {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedSportsTab = "Key Moments"
                }
            }
        }
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        // Use screen height (absolute coordinates) so the calculation is not
        // affected by proxy.size.height shrinking due to keyboard insets.
        let height = max(0, UIScreen.main.bounds.height - frame.minY)

        withAnimation(.easeInOut(duration: duration)) {
            keyboardHeight = height
        }
    }

    private func momentSearchOverlay(detail: ContentDetail, bottomInset: CGFloat) -> some View {
        // Use UIScreen height as the stable baseline so the bar sits flush with
        // the keyboard regardless of whether the portrait poster or 16:9 player
        // is currently shown — both layouts have different heights, which used to
        // shift the overlay's bottom anchor.
        let screenH = UIScreen.main.bounds.height
        let barBottomPadding: CGFloat = keyboardHeight > 0 ? keyboardHeight : max(bottomInset, 10) + 8

        return ZStack(alignment: .bottom) {
            KeyboardOverlayBackdropView()
                .ignoresSafeArea()

            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    dismissMomentSearchOverlay()
                }

            VStack(alignment: .leading, spacing: 10) {
                Text("Explore related moments")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)

                SuggestionChipFlow(
                    suggestions: viewModel.momentSuggestions(for: detail),
                    maxRows: 2,
                    maxItemsPerRow: 2,
                    horizontalPadding: 16,
                    onSelect: { suggestion in
                        momentSearchDraft = suggestion
                        submitMomentSearchOverlay()
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeOut(duration: 0.22), value: isMomentSearchFocused)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.52))

                    TextField("Search for moments for the movie", text: $momentSearchDraft)
                        .focused($isMomentSearchFocused)
                        .keyboardType(.default)
                        .submitLabel(.search)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .tint(Color(hex: "F5A623"))
                        .onSubmit {
                            if momentSearchDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                dismissMomentSearchOverlay()
                            } else {
                                submitMomentSearchOverlay()
                            }
                        }

                }
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: "111111").opacity(0.94))
                        .shadow(color: Color.black.opacity(0.58), radius: 18, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: "F5A623"), Color(hex: "E64AFF"), Color(hex: "3B82F6")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1.4
                                )
                        )
                )
                .padding(.horizontal, 16)
            }
            .padding(.top, 14)
            .padding(.bottom, barBottomPadding)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.04), location: 0),
                        .init(color: Color.black.opacity(0.48), location: 0.42),
                        .init(color: Color.black.opacity(0.86), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blur(radius: 0.8)
                .ignoresSafeArea(edges: .bottom)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        // Explicitly pin to full screen so the bottom anchor is always at
        // UIScreen.main.bounds.height, not wherever the current layout leaves it.
        .frame(width: UIScreen.main.bounds.width, height: screenH)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var momentResultsContent: some View {
        if viewModel.isLoadingMoments {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(.white)
                Text("Finding moments...")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.76))
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(LiquidGlassBackground(cornerRadius: UIConstants.CornerRadius.lg, tone: .dark))
        } else if viewModel.momentsErrorMessage != nil {
            noMomentsDataView
        } else if viewModel.momentResults.isEmpty {
            Button {
                if let detail = viewModel.detail {
                    presentMomentSearchOverlay(for: detail)
                }
            } label: {
                EmptyStateView(title: AppStrings.Detail.moments, message: "Search a scene, dialogue, song, or topic from this title.", systemImage: "sparkles")
                    .padding(.top, 6)
            }
            .buttonStyle(LiquidButtonPressStyle())
            .transaction { $0.animation = nil }
        } else {
            LazyVGrid(columns: momentColumns, spacing: 10) {
                ForEach(viewModel.momentResults) { item in
                    Button {
                        onSelectRecommendation(item)
                    } label: {
                        MomentResultCard(item: item)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
            }
            .padding(.top, 2)
        }
    }

    private var noMomentsDataView: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.28))
            Text("No relevant data available")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.54))
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .padding(.top, 6)
    }

    @ViewBuilder
    private func episodesSection(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.seasons.isEmpty == false {
                seasonSelector
            }

            if viewModel.isLoadingEpisodes {
                HStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("Loading episodes...")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.76))
                }
                .frame(maxWidth: .infinity, minHeight: 96)
                .background(LiquidGlassBackground(cornerRadius: UIConstants.CornerRadius.lg, tone: .dark))
            } else if let message = viewModel.episodesErrorMessage {
                EmptyStateView(title: AppStrings.Detail.episodes, message: message, systemImage: "play.rectangle.on.rectangle")
            } else if viewModel.episodes.isEmpty {
                EmptyStateView(title: AppStrings.Detail.episodes, message: "Episodes are not available for this title yet.", systemImage: "play.rectangle.on.rectangle")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.episodes) { episode in
                        Button {
                            if let playEpisode = onPlayEpisode {
                                playEpisode(episode)
                            } else {
                                onSelectRecommendation(episode)
                            }
                        } label: {
                            EpisodeCard(item: episode, totalWidth: width)
                        }
                        .buttonStyle(LiquidButtonPressStyle())
                    }
                }
            }
        }
    }

    private var seasonSelector: some View {
        let title = viewModel.seasons.first(where: { $0.id == viewModel.selectedSeasonID })?.title ?? "Season 1"
        return Button {
            isSeasonSheetPresented = true
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .tracking(0.4)
                    .foregroundStyle(Color(hex: "F0F0F0"))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(seasonChipBackground)
        }
        .buttonStyle(LiquidButtonPressStyle())
        .sheet(isPresented: $isSeasonSheetPresented) {
            seasonPickerSheet
        }
    }

    private var seasonPickerSheet: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            Text("Select Season")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            Divider().overlay(Color.white.opacity(0.12))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(viewModel.seasons) { season in
                        Button {
                            viewModel.selectSeason(season)
                            isSeasonSheetPresented = false
                        } label: {
                            HStack {
                                Text(season.title)
                                    .font(.system(size: 16, weight: viewModel.selectedSeasonID == season.id ? .semibold : .regular))
                                    .foregroundStyle(.white)

                                Spacer()

                                if viewModel.selectedSeasonID == season.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(hex: "F5A623"))
                                }
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 54)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(LiquidButtonPressStyle())

                        Divider().overlay(Color.white.opacity(0.08)).padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color(hex: "1A1A1A"))
        .presentationDetents([.height(CGFloat(min(viewModel.seasons.count, 6)) * 54 + 120)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(20)
        .presentationBackground(Color(hex: "1A1A1A"))
    }

    private var seasonChipBackground: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 300, bottomLeadingRadius: 300,
            bottomTrailingRadius: 300, topTrailingRadius: 300,
            style: .continuous
        )
        return shape.fill(.ultraThinMaterial)
            .overlay(shape.fill(Color.black.opacity(0.9)))
            .overlay(
                shape.fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.05), location: 0),
                            .init(color: Color(hex: "FF8100").opacity(0.05), location: 1)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            )
            .overlay(shape.stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func castSection(_ detail: ContentDetail) -> some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.lg) {
            if !detail.directorNames.isEmpty {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
                    Text("Director")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.56))

                    Text(detail.directorNames.joined(separator: ", "))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }

            if detail.cast.isEmpty {
                EmptyStateView(title: AppStrings.Detail.castAndMore, message: "Cast information will appear here once we connect the full credits flow.", systemImage: "person.2")
            } else {
                LazyVGrid(columns: recommendationColumns, spacing: UIConstants.Spacing.md) {
                    ForEach(detail.cast) { person in
                        VStack(spacing: UIConstants.Spacing.sm) {
                            CastAvatarTile(person: person, size: UIConstants.Size.posterWidth)
                            Text(person.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(width: UIConstants.Size.posterWidth)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

private struct DetailActionButton: View {
    enum CornerStyle {
        case leading
        case middle
        case trailing
    }

    var systemImage: String? = nil
    var assetImage: String? = nil
    var iconSize: CGFloat = 24
    var cornerStyle: CornerStyle = .middle
    var isHighlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon
                .frame(width: 56, height: 56)
                .background(backgroundShape)
                .contentShape(shape)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    @ViewBuilder
    private var icon: some View {
        if let assetImage {
            Image(assetImage)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: iconSize, height: iconSize)
        } else if let systemImage {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var shape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: cornerStyle == .leading ? 20 : 8,
            bottomLeadingRadius: cornerStyle == .leading ? 20 : 8,
            bottomTrailingRadius: cornerStyle == .trailing ? 20 : 8,
            topTrailingRadius: cornerStyle == .trailing ? 20 : 8,
            style: .continuous
        )
    }

    private var backgroundShape: some View {
        shape
            .fill(.ultraThinMaterial)
            .overlay(shape.fill(Color.white.opacity(0.1)))
            .overlay(
                shape.stroke(
                    isHighlighted ? Color(hex: "FF5E00") : Color.white.opacity(0.08),
                    lineWidth: isHighlighted ? 2 : 1
                )
            )
            .overlay(
                shape.fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FF5E00").opacity(isHighlighted ? 0.42 : 0.08),
                            Color(hex: "7818B4").opacity(isHighlighted ? 0.36 : 0.05),
                            Color.clear
                        ],
                        center: .bottomTrailing,
                        startRadius: 1,
                        endRadius: 44
                    )
                )
                .blendMode(.screen)
            )
            .shadow(color: Color.black.opacity(0.32), radius: 7, x: 0, y: 4)
    }
}

private struct DetailRecommendationCard: View {
    let item: StorefrontItem
    let size: CGSize
    let onSelect: (StorefrontItem) -> Void

    var body: some View {
        Button {
            onSelect(item)
        } label: {
            ZStack(alignment: .bottom) {
                PosterImageView(
                    url: item.imageURL(for: "0-2x3", width: Int(size.width * 3)),
                    size: size,
                    cornerRadius: 0
                )

                if item.isPremium || item.contentType.lowercased().contains("episode") {
                    Text(item.contentType.lowercased().contains("episode") ? "New Episode" : "New Movie")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .frame(height: 18)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: "4732FF").opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color(hex: "CFCFCF"), lineWidth: 1)
                                )
                        )
                        .padding(.bottom, 8)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

private struct DetailFeaturedRecommendationCard: View {
    let item: StorefrontItem
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PosterImageView(
                url: item.imageURL(for: "0-2x3", width: Int(width * 3)),
                size: CGSize(width: width, height: width * 1.78),
                cornerRadius: 0
            )

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.2), Color.black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 9) {
                Text(item.title.uppercased())
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(item.description.nilIfEmpty ?? item.primaryMetaText.nilIfEmpty ?? "A gripping story with powerful performances and unexpected twists.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(item.watchLabel == "Watch Now" ? "Watch Full Movie" : item.watchLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(LiquidGlassBackground(cornerRadius: 999, tone: .light, isHighlighted: true))

                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(LiquidGlassCircleBackground(tone: .dark))
                }
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 18)
        }
        .frame(width: width, height: width * 1.78)
        .clipped()
    }
}

private struct MomentResultCard: View {
    let item: StorefrontItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { proxy in
                PosterImageView(
                    url: item.imageURL(for: "0-16x9", width: Int(proxy.size.width * 3)),
                    size: proxy.size,
                    cornerRadius: 10
                )
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.02),
                    Color.black.opacity(0.28),
                    Color.black.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Image(systemName: "play.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.8))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.88)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(item.description.nilIfEmpty ?? item.primaryMetaText.nilIfEmpty ?? item.contentType)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct EpisodeCard: View {
    let item: StorefrontItem
    let totalWidth: CGFloat

    private let thumbSize = CGSize(width: 120, height: 84)

    private var durationText: String? {
        guard let secs = item.runtimeSeconds, secs > 0 else { return nil }
        let m = secs / 60; let s = secs % 60
        return String(format: "%d:%02d", m, s)
    }

    private var badges: [String] {
        var result: [String] = []
        if let r = item.rating?.nilIfEmpty { result.append(r) }
        if let q = item.quality?.nilIfEmpty { result.append(q) }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Row: thumbnail LEFT + info RIGHT ──────────────────────────
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail with duration overlay
                ZStack(alignment: .bottomLeading) {
                    PosterImageView(
                        url: item.imageURL(for: "0-16x9", width: Int(thumbSize.width * 3)),
                        size: thumbSize,
                        cornerRadius: 8
                    )
                    .frame(width: thumbSize.width, height: thumbSize.height)

                    if let dur = durationText {
                        Text(dur)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.74))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .padding(5)
                    }
                }
                .frame(width: thumbSize.width, height: thumbSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Info column
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let meta = item.primaryMetaText.nilIfEmpty {
                        Text(meta)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    if !badges.isEmpty {
                        HStack(spacing: 5) {
                            ForEach(badges.prefix(4), id: \.self) { badge in
                                Text(badge)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.78))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(Color.white.opacity(0.26), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 14)

            // Description full-width below
            if let desc = item.description.nilIfEmpty {
                Text(desc)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(3)
                    .padding(.bottom, 14)
            }

            // Row divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CastAvatarTile: View {
    let person: ContentPerson
    let size: CGFloat

    var body: some View {
        ZStack {
            if let url = person.imageURL(width: Int(size * 3)) {
                PosterImageView(
                    url: url,
                    size: CGSize(width: size, height: size),
                    cornerRadius: UIConstants.CornerRadius.lg
                )
            } else {
                fallbackAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous))
    }

    private var fallbackAvatar: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "2B173A"),
                    Color(hex: "141018"),
                    Color(hex: "3A170D")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(hex: "F5A623").opacity(0.18))
                .blur(radius: 18)
                .offset(x: -18, y: -16)

            Circle()
                .fill(Color(hex: "7818B4").opacity(0.2))
                .blur(radius: 18)
                .offset(x: 18, y: 16)

            Text(person.initials)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.white)
        }
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

// Canvas-based confetti rain for correct KBC answer
private struct KBCConfettiView: View {
    private struct Particle {
        let x: CGFloat
        let speed: CGFloat
        let delay: CGFloat
        let colorIdx: Int
        let spinDir: Double
        let tall: Bool
    }

    private static let palette: [Color] = [
        Color(hex: "FF3B30"), Color(hex: "FF9500"), Color(hex: "FFCC00"),
        Color(hex: "34C759"), Color(hex: "007AFF"), Color(hex: "AF52DE"),
        Color(hex: "FFAC33"), Color(hex: "FF2D55")
    ]

    private static let particles: [Particle] = (0..<72).map { idx in
        let f = Double(idx)
        return Particle(
            x: CGFloat(sin(f * 2.399) * 0.5 + 0.5),
            speed: CGFloat(120 + abs(sin(f * 3.1)) * 190),
            delay: CGFloat((sin(f * 5.7) * 0.5 + 0.5) * 1.3),
            colorIdx: idx % palette.count,
            spinDir: sin(f * 2.1) >= 0 ? 260 : -260,
            tall: idx % 3 == 0
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = CGFloat(fmod(timeline.date.timeIntervalSinceReferenceDate * 0.48, 2.9))
                for p in Self.particles {
                    let elapsed = max(0, t - p.delay)
                    guard elapsed > 0 else { continue }
                    let px = p.x * size.width
                    let py = elapsed * p.speed - 30
                    guard py < size.height + 50 else { continue }
                    let angle = Angle.degrees(Double(elapsed) * p.spinDir)
                    let w: CGFloat = p.tall ? 5 : 10
                    let h: CGFloat = p.tall ? 10 : 4
                    context.drawLayer { ctx in
                        ctx.translateBy(x: px, y: py)
                        ctx.rotate(by: angle)
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: -w / 2, y: -h / 2, width: w, height: h)),
                            with: .color(Self.palette[p.colorIdx])
                        )
                    }
                }
            }
        }
    }
}

// Hexagonal KBC-style option shape (pointed left/right ends)
private struct KBCHexShape: Shape {
    func path(in rect: CGRect) -> Path {
        let indent = rect.height * 0.38
        var p = Path()
        p.move(to: CGPoint(x: indent, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX - indent, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - indent, y: rect.maxY))
        p.addLine(to: CGPoint(x: indent, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

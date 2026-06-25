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
    .init(id: "1", username: "cricket_fan99", text: "Bumrah on fire 🔥 hat-trick incoming??", avatarLetter: "C", colorHex: "E53935"),
    .init(id: "2", username: "sports_live", text: "SL top order struggling badly 😬", avatarLetter: "S", colorHex: "1E88E5"),
    .init(id: "3", username: "IND_supporter", text: "IND 210/5 in 20 overs, great target 💯 what a knock from Rohit!", avatarLetter: "I", colorHex: "43A047"),
    .init(id: "4", username: "maxwellfan_", text: "Maxwell batting like a god rn!", avatarLetter: "M", colorHex: "FB8C00"),
    .init(id: "5", username: "rohit_official", text: "Rohit anchored brilliantly today 🏏 captain's knock 💙", avatarLetter: "R", colorHex: "8E24AA"),
    .init(id: "6", username: "cricket_world", text: "Close match! SL can still chase this 🤞", avatarLetter: "W", colorHex: "00897B"),
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
    .init(id: "1", name: "R Sharma (c)", dismissal: "b Wellalage", r: "53", b: "48", fours: "7", sixes: "2", sr: "110.4", isAtCrease: false),
    .init(id: "2", name: "S Gill", dismissal: "b Wellalage", r: "19", b: "25", fours: "2", sixes: "0", sr: "76.0", isAtCrease: false),
    .init(id: "3", name: "V Kohli", dismissal: "c Shanaka b Wellalage", r: "3", b: "12", fours: "0", sixes: "0", sr: "25.0", isAtCrease: false),
    .init(id: "4", name: "I Kishan", dismissal: "c Wellalage b Asalanka", r: "44", b: "29", fours: "3", sixes: "2", sr: "151.7", isAtCrease: false),
    .init(id: "5", name: "D Warner", dismissal: "not out", r: "0", b: "1", fours: "0", sixes: "0", sr: "0.0", isAtCrease: true),
    .init(id: "6", name: "G Maxwell", dismissal: "not out", r: "52", b: "38", fours: "4", sixes: "3", sr: "136.8", isAtCrease: true),
]

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
    let onBack: () -> Void
    let onPlay: (ContentDetail, StorefrontItem?) -> Void
    let onSelectRecommendation: (StorefrontItem) -> Void
    @State private var isDescriptionExpanded = false
    @State private var isMomentSearchOverlayPresented = false
    @State private var isMockInteractionPresented = false
    @State private var mockInteractionSelection: String?
    @State private var mockInteractionShowsResult = false
    @State private var mockInteractionCountdown = 4
    @State private var momentSearchDraft = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var momentAutoScrollToken = 0
    @FocusState private var isMomentSearchFocused: Bool
    // Sports interactive
    @State private var selectedSportsTab = "Live Feed"
    @State private var liveChatInput = ""
    @State private var sportsPollAnswer: String? = nil
    @FocusState private var isChatInputFocused: Bool

    private let recommendationColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
    private let momentColumns = [GridItem(.flexible(), spacing: 10)]
    private let detailTabsAnchorID = "detail-tabs-anchor"
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                content(width: proxy.size.width)
                    .ignoresSafeArea(edges: .top)

                if let detail = viewModel.detail, isMomentSearchOverlayPresented {
                    momentSearchOverlay(detail: detail, bottomInset: proxy.safeAreaInsets.bottom)
                        .zIndex(20)
                }

                if let detail = viewModel.detail, isMockInteractionPresented {
                    mockShowInteractionOverlay(detail: detail)
                        .zIndex(30)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .animation(.easeInOut(duration: 0.22), value: isMomentSearchOverlayPresented)
            .animation(.easeInOut(duration: 0.22), value: isMockInteractionPresented)
            .task(id: viewModel.requestKey) {
                isDescriptionExpanded = false
                dismissMomentSearchOverlay()
                dismissMockInteraction()
                await viewModel.loadIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                updateKeyboardHeight(from: notification, containerHeight: proxy.size.height)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    keyboardHeight = 0
                }
            }
        }
    }

    @ViewBuilder
    private func content(width: CGFloat) -> some View {
        if let detail = viewModel.detail {
            let kind = DetailPresentationKind.resolve(seed: viewModel.seed, detail: detail)

            ZStack(alignment: .top) {
                Color(hex: "0A0A0A").ignoresSafeArea()

                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            hero(detail, width: width)
                                .frame(height: heroHeight(for: width))

                            if kind == .sportsInteractive {
                                sportsDetailContent(detail, width: width)
                                    .padding(.horizontal, 16)
                                    .padding(.top, -64)
                            } else {
                                detailContent(detail, kind: kind, width: width)
                                    .padding(.horizontal, 16)
                                    .padding(.top, -64)
                            }
                        }
                        .padding(.bottom, 42)
                    }
                    .ignoresSafeArea(edges: .top)
                    .onChange(of: momentAutoScrollToken) { _, _ in
                        guard viewModel.selectedTab == AppStrings.Detail.moments else { return }

                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(180))
                            withAnimation(.easeInOut(duration: 0.72)) {
                                scrollProxy.scrollTo(detailTabsAnchorID, anchor: UnitPoint(x: 0.5, y: 0.09))
                            }
                        }
                    }
                    .onChange(of: viewModel.momentResults.count) { _, count in
                        guard count > 0, viewModel.selectedTab == AppStrings.Detail.moments else { return }

                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(240))
                            withAnimation(.easeInOut(duration: 0.82)) {
                                scrollProxy.scrollTo(detailTabsAnchorID, anchor: UnitPoint(x: 0.5, y: 0.09))
                            }
                        }
                    }
                }
            }
        } else if viewModel.isLoading {
            LoadingView()
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

    private func hero(_ detail: ContentDetail, width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            PosterImageView(
                url: detail.imageURL(for: "0-2x3", width: Int(width * 3)),
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
        max(413, width)
    }

    private func detailContent(_ detail: ContentDetail, kind: DetailPresentationKind, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            titleArt(detail)
            metaLine(detail)
            watchButton(detail, kind: kind)
            descriptionBlock(detail)
            previewLabel(detail)
            actionButtonRow(detail, kind: kind)
            sponsorRow(detail)
            tabRow(detail)
                .id(detailTabsAnchorID)
            tabContent(detail, width: width)
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
        Text(detail.metaLine)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color(hex: "BBBBBB"))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity)
    }

    private func watchButton(_ detail: ContentDetail, kind: DetailPresentationKind) -> some View {
        Button {
            onPlay(detail, viewModel.seed)
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

    // MARK: - Sports Detail (tab-based, Figma-accurate)

    private func sportsDetailContent(_ detail: ContentDetail, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Series description
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

            // 3 action buttons (notification, schedule, AI search)
            HStack(spacing: 8) {
                DetailActionButton(systemImage: "bell.fill", cornerStyle: .leading, action: {})
                DetailActionButton(systemImage: "list.bullet.rectangle", action: {})
                DetailActionButton(systemImage: AppIcons.Action.sparkles, cornerStyle: .trailing, isHighlighted: true) {
                    presentMomentSearchOverlay(for: detail)
                }
            }
            .padding(.top, 14)

            // Tab bar
            sportsTabRow
                .padding(.top, 20)

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)

            // Tab content
            sportsTabContent(detail, width: width)
                .padding(.top, 4)
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
            // Chat messages
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sportsLiveChatMessages) { msg in
                    liveChatRow(msg)
                }

                // Embedded poll card
                sportsPollInChat
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            .padding(.top, 10)

            // Emoji reaction bar
            HStack(spacing: 0) {
                ForEach(["😜", "😍", "😏", "💀", "👏", "🤨", "❤️", "😂"], id: \.self) { emoji in
                    Button {
                        // reaction tap
                    } label: {
                        Text(emoji)
                            .font(.system(size: 22))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
            }
            .padding(.top, 14)

            // Chat text input
            HStack(spacing: 0) {
                TextField("", text: $liveChatInput, prompt: Text("Add a comment…").foregroundStyle(.white.opacity(0.36)))
                    .focused($isChatInputFocused)
                    .submitLabel(.send)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                    .padding(.leading, 16)
                    .padding(.vertical, 16)

                Button(action: {}) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.58))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(LiquidButtonPressStyle())

                Button(action: {}) {
                    Text("GIF")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white.opacity(0.58))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(LiquidButtonPressStyle())
                .padding(.trailing, 4)
            }
            .background(
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 27, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
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

            Text("Will SL cross 150 in this innings?")
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

    // MARK: Scorecard tab

    private var sportsScorecardTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Live score header
            sportsLiveScoreHeader
                .padding(.top, 12)

            // Current over
            sportsCurrentOverCard

            // Batting scorecard table
            sportsBattingTable

            // Win probability
            sportsWinProbabilityCard
        }
    }

    private var sportsLiveScoreHeader: some View {
        HStack(spacing: 0) {
            VStack(alignment: .center, spacing: 4) {
                Text("IND")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                Text("210-5")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Over 20")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.52))
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                Text("LIVE")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .frame(height: 18)
                    .background(Capsule().fill(Color(hex: "E50914")))

                Text("vs")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .frame(width: 52)

            VStack(alignment: .center, spacing: 4) {
                Text("SL")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                Text("48-2")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Over 5.4")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.52))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "08111F"), Color(hex: "1A2940")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: "72F6A2").opacity(0.28), lineWidth: 1)
                )
        )
    }

    private var sportsCurrentOverCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("J Bumrah")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("3.5 – 8 – 1")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.56))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("CRR 10.2")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "72F6A2"))
                    Text("Need 163 off 85 balls")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.52))
                }
            }

            HStack(spacing: 8) {
                Text("This over:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.44))

                HStack(spacing: 5) {
                    ForEach(["0", "4", "W", "0", "4", "1lb"], id: \.self) { ball in
                        Text(ball)
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(
                                ball == "W" ? Color.white :
                                ball == "4" || ball == "6" ? Color.black :
                                Color.white
                            )
                            .frame(width: 28, height: 28)
                            .background(
                                Circle().fill(
                                    ball == "W" ? Color(hex: "E50914") :
                                    ball == "4" ? Color(hex: "22C55E") :
                                    ball == "6" ? Color(hex: "F59E0B") :
                                    Color.white.opacity(0.14)
                                )
                            )
                    }
                }
            }
        }
        .padding(14)
        .background(LiquidGlassBackground(cornerRadius: 14, tone: .dark))
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
                Text("SR").frame(width: 46, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white.opacity(0.44))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)

            ForEach(scorecardInnningsData) { batter in
                sportsBatterRow(batter)
                if batter.id != scorecardInnningsData.last?.id {
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                }
            }
        }
        .background(LiquidGlassBackground(cornerRadius: 14, tone: .dark))
    }

    private func sportsBatterRow(_ batter: ScorecardBatter) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
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
                    .foregroundStyle(.white.opacity(0.36))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(batter.r).frame(width: 34, alignment: .trailing)
                .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
            Text(batter.b).frame(width: 30, alignment: .trailing)
                .font(.system(size: 12, weight: .regular)).foregroundStyle(.white.opacity(0.56))
            Text(batter.fours).frame(width: 28, alignment: .trailing)
                .font(.system(size: 12, weight: .regular)).foregroundStyle(.white.opacity(0.56))
            Text(batter.sixes).frame(width: 28, alignment: .trailing)
                .font(.system(size: 12, weight: .regular)).foregroundStyle(.white.opacity(0.56))
            Text(batter.sr).frame(width: 46, alignment: .trailing)
                .font(.system(size: 11, weight: .regular)).foregroundStyle(.white.opacity(0.44))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var sportsWinProbabilityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Win Probability")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            ForEach([("India", "32%", 0.32, "4891E0"), ("Sri Lanka", "68%", 0.68, "72F6A2")], id: \.0) { team in
                HStack(spacing: 10) {
                    Text(team.0)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 72, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color(hex: team.3))
                                .frame(width: geo.size.width * team.2, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text(team.1)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: team.3))
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(14)
        .background(LiquidGlassBackground(cornerRadius: 14, tone: .dark))
        .padding(.bottom, 16)
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
            DetailActionButton(assetImage: "clapperboard", cornerStyle: .leading, action: {})
            DetailActionButton(assetImage: "download", action: {})
            DetailActionButton(assetImage: "bookmark-plus", action: {})
            DetailActionButton(assetImage: "thumbs-up-down") {
                if detail.supportsEpisodes || kind == .showInteractive {
                    presentMockInteraction()
                }
            }
            DetailActionButton(assetImage: "share", iconSize: 22, action: {})
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
        var tabs = [
            AppStrings.Detail.moreLikeThis,
            AppStrings.Detail.moments
        ]

        if detail.supportsEpisodes {
            tabs.append(AppStrings.Detail.episodes)
        }

        tabs.append(AppStrings.Detail.castAndMore)
        return tabs
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

        presentMomentSearchOverlay(for: detail)
    }

    private func presentMomentSearchOverlay(for detail: ContentDetail) {
        guard detail.momentSearchEnabled else { return }
        viewModel.selectTab(AppStrings.Detail.moments)
        momentSearchDraft = viewModel.momentQuery

        withAnimation(.easeInOut(duration: 0.26)) {
            isMomentSearchOverlayPresented = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
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
        mockInteractionSelection = nil
        mockInteractionShowsResult = false
        mockInteractionCountdown = 4

        withAnimation(.easeInOut(duration: 0.22)) {
            isMockInteractionPresented = true
        }
    }

    private func dismissMockInteraction() {
        isMockInteractionPresented = false
        mockInteractionSelection = nil
        mockInteractionShowsResult = false
        mockInteractionCountdown = 4
    }

    private func answerMockInteraction(_ answer: String) {
        guard mockInteractionSelection == nil else { return }
        mockInteractionSelection = answer

        Task { @MainActor in
            for value in stride(from: 3, through: 1, by: -1) {
                mockInteractionCountdown = value
                try? await Task.sleep(for: .milliseconds(420))
            }

            mockInteractionShowsResult = true
            try? await Task.sleep(for: .seconds(1.6))

            if isMockInteractionPresented {
                dismissMockInteraction()
            }
        }
    }

    private func mockShowInteractionOverlay(detail: ContentDetail) -> some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissMockInteraction()
                }

            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 42, height: 5)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quick Question")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)

                        Text(mockInteractionShowsResult ? "Answer locked" : "Timer \(mockInteractionCountdown)s")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "FFD166"))
                    }

                    Spacer()

                    Button {
                        dismissMockInteraction()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }

                Text("What happens next in \(detail.title)?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.86))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    mockAnswerButton("The hero discovers a clue", isCorrect: true)
                    mockAnswerButton("A new rival enters", isCorrect: false)
                    mockAnswerButton("The case gets closed", isCorrect: false)
                }

                if mockInteractionShowsResult {
                    HStack(spacing: 8) {
                        Image(systemName: mockInteractionSelection == "The hero discovers a clue" ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(mockInteractionSelection == "The hero discovers a clue" ? Color(hex: "72F6A2") : Color(hex: "FF6464"))

                        Text(mockInteractionSelection == "The hero discovers a clue" ? "Correct answer. Nice pick." : "Wrong answer. Correct one was clue.")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "271145"), Color(hex: "121218"), Color(hex: "3A1907")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.48), radius: 30, x: 0, y: 18)
            )
            .padding(.horizontal, 22)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func mockAnswerButton(_ title: String, isCorrect: Bool) -> some View {
        let isSelected = mockInteractionSelection == title
        let isLocked = mockInteractionSelection != nil
        let resultColor = isCorrect ? Color(hex: "22C55E") : Color(hex: "FF6464")

        return Button {
            answerMockInteraction(title)
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                if isLocked && (isSelected || isCorrect) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(resultColor)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.16 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(isLocked && (isSelected || isCorrect) ? resultColor.opacity(0.75) : Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .disabled(isLocked)
        .buttonStyle(LiquidButtonPressStyle())
    }

    private func submitMomentSearchOverlay() {
        let query = momentSearchDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return }

        dismissMomentSearchOverlay()
        viewModel.submitMomentSearch(query)
        momentAutoScrollToken += 1
    }

    private func updateKeyboardHeight(from notification: Notification, containerHeight: CGFloat) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let height = max(0, containerHeight - frame.minY)

        withAnimation(.easeInOut(duration: duration)) {
            keyboardHeight = height
        }
    }

    private func momentSearchOverlay(detail: ContentDetail, bottomInset: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
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
            .padding(.bottom, overlayBottomPadding(bottomInset: bottomInset))
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
    }

    private func overlayBottomPadding(bottomInset: CGFloat) -> CGFloat {
        keyboardHeight > 0 ? keyboardHeight + 8 : max(bottomInset, 10) + 8
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
        } else if let message = viewModel.momentsErrorMessage {
            EmptyStateView(title: AppStrings.Detail.moments, message: message, systemImage: "sparkles")
                .padding(.top, 6)
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

    @ViewBuilder
    private func episodesSection(width: CGFloat) -> some View {
        if viewModel.isLoadingEpisodes {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(.white)
                Text("Loading episodes...")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.76))
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(LiquidGlassBackground(cornerRadius: UIConstants.CornerRadius.lg, tone: .dark))
            .padding(.top, 8)
        } else if let message = viewModel.episodesErrorMessage {
            EmptyStateView(title: AppStrings.Detail.episodes, message: message, systemImage: "play.rectangle.on.rectangle")
                .padding(.top, 8)
        } else if viewModel.episodes.isEmpty {
            EmptyStateView(title: AppStrings.Detail.episodes, message: "Episodes are not available for this title yet.", systemImage: "play.rectangle.on.rectangle")
                .padding(.top, 8)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.episodes) { episode in
                    Button {
                        onSelectRecommendation(episode)
                    } label: {
                        EpisodeCard(item: episode, width: width - 32)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }
            }
            .padding(.top, 8)
        }
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
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .center) {
                PosterImageView(
                    url: item.imageURL(for: "0-16x9", width: Int(width * 3)),
                    size: CGSize(width: width, height: width * 9 / 16),
                    cornerRadius: 10
                )

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.18), Color.black.opacity(0.68)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.84))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.9)))
            }
            .frame(width: width, height: width * 9 / 16)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(item.description.nilIfEmpty ?? item.primaryMetaText.nilIfEmpty ?? item.watchLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
            }
        }
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

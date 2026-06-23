import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    let profileName: String
    let prefersVoiceAISearch: Bool
    let onBack: () -> Void
    let onSelectItem: (StorefrontItem) -> Void
    @FocusState private var isSearchFocused: Bool
    @State private var aiOverlayMode: AISearchOverlayMode?
    @State private var aiQuery = ""
    @State private var aiTextPrompt = ""
    @State private var voiceSubmitTask: Task<Void, Never>?
    @StateObject private var speechService = SpeechRecognitionService()

    private let aiPromptSuggestions = [
        "Show me Hindi thriller movies",
        "Weekend family movies",
        "Top South action films",
        "Thrillers under 2 hours",
        "Something emotional to watch",
        "Latest trending shows",
        "Feel-good comedy movies",
        "Binge-worthy crime series",
        "Underrated Sony LIV titles"
    ]

    private let columns = [
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs),
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs),
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs)
    ]

    private var recommendedClips: [StorefrontItem] {
        Array(viewModel.popularItems.prefix(4))
    }

    private var popularSearchItems: [StorefrontItem] {
        Array(viewModel.popularItems.dropFirst(4).prefix(12))
    }

    private var shouldShowResultFilters: Bool {
        !viewModel.normalizedQuery.isEmpty && viewModel.availableFilters.count > 1
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    content
                }

                if aiOverlayMode == nil {
                    bottomSearchDock(bottomInset: proxy.safeAreaInsets.bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(searchBackground.ignoresSafeArea())

            if let aiOverlayMode {
                aiOverlay(mode: aiOverlayMode, topInset: proxy.safeAreaInsets.top)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onDisappear {
            voiceSubmitTask?.cancel()
            speechService.stop()
        }
        .onChange(of: speechService.transcript) { _, transcript in
            scheduleVoiceSearch(for: transcript)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.normalizedQuery.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    searchSectionHeader(title: "Recommended Clips", showsChevron: false)
                        .padding(.horizontal, UIConstants.Spacing.lg)
                        .padding(.top, 18)

                    if recommendedClips.isEmpty {
                        EmptyStateView(title: AppStrings.Search.popular, message: AppStrings.Search.emptyPopular, systemImage: "sparkles.tv")
                            .padding(.horizontal, UIConstants.Spacing.lg)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(recommendedClips) { item in
                                    SearchPosterCard(
                                        item: item,
                                        size: CGSize(width: 111, height: 197),
                                        showsPlayIcon: true,
                                        onSelect: onSelectItem
                                    )
                                }
                            }
                            .padding(.horizontal, UIConstants.Spacing.lg)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        searchSectionHeader(title: "Popular Search", showsChevron: false)

                        if popularSearchItems.isEmpty {
                            EmptyStateView(title: AppStrings.Search.popular, message: AppStrings.Search.emptyPopular, systemImage: AppIcons.Navigation.search)
                        } else {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(popularSearchItems) { item in
                                    SearchPosterCard(
                                        item: item,
                                        size: CGSize(width: 124, height: 186),
                                        showsPlayIcon: false,
                                        onSelect: onSelectItem
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                }
                .padding(.bottom, 148)
            }
            .simultaneousGesture(TapGesture().onEnded { isSearchFocused = false })
            .scrollDismissesKeyboard(.interactively)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if viewModel.isLoading && viewModel.results.isEmpty {
                        LoadingView()
                            .padding(.top, 80)
                    } else if let errorMessage = viewModel.errorMessage, viewModel.results.isEmpty {
                        ErrorView(title: AppStrings.Search.unavailableTitle, message: errorMessage, onRetry: nil)
                            .padding(.horizontal, UIConstants.Spacing.lg)
                            .padding(.top, 60)
                    } else if viewModel.displayedResults.isEmpty {
                        EmptyStateView(title: AppStrings.Search.noResults, message: viewModel.normalizedQuery, systemImage: AppIcons.Navigation.search)
                            .padding(.horizontal, UIConstants.Spacing.lg)
                            .padding(.top, 60)
                    } else {
                        let featureTitle = viewModel.normalizedQuery.capitalized

                        VStack(alignment: .leading, spacing: 22) {
                            searchSectionHeader(title: featureTitle, showsChevron: false)
                                .padding(.horizontal, UIConstants.Spacing.lg)
                                .padding(.top, 14)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(viewModel.displayedResults.prefix(8))) { item in
                                        SearchPosterCard(
                                            item: item,
                                            size: CGSize(width: 111, height: 197),
                                            showsPlayIcon: true,
                                            onSelect: onSelectItem
                                        )
                                    }
                                }
                                .padding(.horizontal, UIConstants.Spacing.lg)
                            }

                            SearchResultRail(
                                title: "Movies",
                                items: items(forFilterID: "movies", fallback: viewModel.displayedResults),
                                onSelect: onSelectItem
                            )

                            SearchResultRail(
                                title: "Shows",
                                items: items(
                                    forFilterID: "shows",
                                    fallback: Array(viewModel.displayedResults.dropFirst(min(4, viewModel.displayedResults.count)))
                                ),
                                onSelect: onSelectItem
                            )
                        }
                    }
                }
                .padding(.bottom, shouldShowResultFilters ? 184 : 134)
            }
            .simultaneousGesture(TapGesture().onEnded { isSearchFocused = false })
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var searchBackground: some View {
        ZStack {
            Color.black

            if !viewModel.normalizedQuery.isEmpty {
                LinearGradient(
                    colors: [Color(hex: "FF5E00"), Color(hex: "4418B4")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 150)
                .blur(radius: 120)
                .opacity(0.9)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private func bottomSearchDock(bottomInset: CGFloat) -> some View {
        VStack(spacing: 12) {
            if shouldShowResultFilters {
                SearchFilterDock(
                    filters: Array(viewModel.availableFilters.prefix(4)),
                    selectedFilterID: viewModel.selectedFilterID,
                    onSelect: { filter in
                        viewModel.selectedFilterID = filter.id
                        isSearchFocused = false
                    }
                )
            }

            HStack(spacing: 12) {
                SearchFieldView(
                    text: $viewModel.query,
                    isFocused: $isSearchFocused,
                    placeholder: "Search Movies, Shows, Sports...",
                    iconName: "magnifyingglass",
                    onSubmit: {
                        isSearchFocused = false
                    }
                )
                .frame(height: 54)

                Button(action: beginAISearch) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "FFB347"), Color(hex: "FF5E00"), Color(hex: "7B2CFF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.4
                            )
                            .frame(width: 30, height: 30)

                        Image(systemName: AppIcons.Action.mic)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 54, height: 54)
                    .background(LiquidGlassCircleBackground(tone: .dark, isHighlighted: true))
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
            .padding(.horizontal, UIConstants.Spacing.lg)
        }
        .padding(.top, 10)
        .padding(.bottom, max(bottomInset, 12))
        .background(searchDockBackdrop(height: shouldShowResultFilters ? 166 : 118))
    }

    private func searchSectionHeader(title: String, showsChevron: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            if showsChevron {
                Image(systemName: AppIcons.Navigation.next)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.84))
            }
        }
    }

    private func momentChip(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.86))
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(
                LiquidGlassBackground(cornerRadius: 8, tone: .dark)
            )
    }

    private func items(forFilterID filterID: String, fallback: [StorefrontItem]) -> [StorefrontItem] {
        let filtered = viewModel.results.filter { $0.derivedSearchFilter.id == filterID }
        return Array((filtered.isEmpty ? fallback : filtered).prefix(8))
    }

    @ViewBuilder
    private func aiOverlay(mode: AISearchOverlayMode, topInset: CGFloat) -> some View {
        switch mode {
        case .voiceListening:
            VoiceSearchListeningView(
                topInset: topInset,
                transcript: speechService.transcript,
                statusText: speechService.statusText,
                isRecording: speechService.isRecording,
                onBack: closeAISearch,
                onToggleRecording: toggleVoiceRecording
            )
        case .voiceResults:
            VoiceSearchResultsView(
                topInset: topInset,
                transcript: aiQuery,
                viewModel: viewModel,
                onBack: closeAISearch,
                onSelectItem: onSelectItem
            )
        case .textPrompt:
            AISearchPromptView(
                topInset: topInset,
                prompt: $aiTextPrompt,
                suggestions: aiPromptSuggestions,
                onBack: closeAISearch,
                onSelectSuggestion: submitTextAISearch,
                onSubmit: submitTextAISearch,
                onVoiceTap: beginVoiceSearch
            )
        case .textResults:
            AISearchTextResultsView(
                topInset: topInset,
                query: aiQuery,
                viewModel: viewModel,
                onBack: closeAISearch,
                onSelectItem: onSelectItem,
                onFollowUpTap: submitTextAISearch
            )
        }
    }

    private func beginAISearch() {
        prefersVoiceAISearch ? beginVoiceSearch() : beginTextAISearch()
    }

    private func beginTextAISearch() {
        isSearchFocused = false
        aiQuery = ""
        aiTextPrompt = ""

        withAnimation(.easeInOut(duration: 0.24)) {
            aiOverlayMode = .textPrompt
        }
    }

    private func beginVoiceSearch() {
        voiceSubmitTask?.cancel()
        isSearchFocused = false
        aiQuery = ""
        speechService.reset()

        withAnimation(.easeInOut(duration: 0.24)) {
            aiOverlayMode = .voiceListening
        }

        Task {
            await speechService.start()
        }
    }

    private func toggleVoiceRecording() {
        if speechService.isRecording {
            speechService.stop()
            submitVoiceSearchIfPossible(speechService.transcript)
        } else {
            Task {
                await speechService.start()
            }
        }
    }

    private func scheduleVoiceSearch(for transcript: String) {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard aiOverlayMode == .voiceListening, !trimmed.isEmpty else { return }

        voiceSubmitTask?.cancel()
        voiceSubmitTask = Task {
            try? await Task.sleep(for: .milliseconds(1400))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                submitVoiceSearchIfPossible(trimmed)
            }
        }
    }

    private func submitVoiceSearchIfPossible(_ transcript: String) {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        aiQuery = trimmed
        viewModel.query = trimmed
        speechService.stop()

        withAnimation(.easeInOut(duration: 0.24)) {
            aiOverlayMode = .voiceResults
        }
    }

    private func submitTextAISearch(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        aiQuery = trimmed
        aiTextPrompt = trimmed
        viewModel.query = trimmed

        withAnimation(.easeInOut(duration: 0.24)) {
            aiOverlayMode = .textResults
        }
    }

    private func closeAISearch() {
        voiceSubmitTask?.cancel()
        voiceSubmitTask = nil
        speechService.reset()
        withAnimation(.easeInOut(duration: 0.22)) {
            aiOverlayMode = nil
        }
    }
}

private enum AISearchOverlayMode: Equatable {
    case voiceListening
    case voiceResults
    case textPrompt
    case textResults
}

private struct SearchPosterCard: View {
    let item: StorefrontItem
    var size = CGSize(width: 112, height: 168)
    var imageRatio = "0-2x3"
    var showsPlayIcon = true
    let onSelect: (StorefrontItem) -> Void

    var body: some View {
        Button {
            onSelect(item)
        } label: {
            ZStack {
                PosterImageView(
                    url: item.imageURL(for: imageRatio, width: Int(size.width * 4)),
                    size: size,
                    cornerRadius: 6
                )

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.18), Color.black.opacity(0.42)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if showsPlayIcon {
                    Image(systemName: AppIcons.Action.playCircle)
                        .font(.system(size: min(size.width, size.height) * 0.26, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92), .white.opacity(0.22))
                }
            }
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

private struct SearchResultRail: View {
    let title: String
    let items: [StorefrontItem]
    var cardSize = CGSize(width: 188, height: 106)
    var imageRatio = "0-16x9"
    let onSelect: (StorefrontItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchRailTitle
                .padding(.horizontal, UIConstants.Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            SearchPosterCard(
                                item: item,
                                size: cardSize,
                                imageRatio: imageRatio,
                                showsPlayIcon: false,
                                onSelect: onSelect
                            )

                            Text(item.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.92))
                                .lineLimit(1)
                                .frame(width: cardSize.width, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
            }
        }
    }

    private var searchRailTitle: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Image(systemName: AppIcons.Navigation.next)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.84))

            Spacer()
        }
    }
}

private struct SearchFilterDock: View {
    let filters: [SearchFilter]
    let selectedFilterID: String
    let onSelect: (SearchFilter) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(filters) { filter in
                Button {
                    onSelect(filter)
                } label: {
                    Text(filter.title)
                        .font(.system(size: 13, weight: selectedFilterID == filter.id ? .bold : .medium))
                        .foregroundStyle(selectedFilterID == filter.id ? .white : Color.white.opacity(0.52))
                        .lineLimit(1)
                        .frame(width: 70, height: 36)
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
        }
        .padding(2)
        .background(LiquidGlassBackground(cornerRadius: 22, tone: .dark))
    }
}

private struct FlexibleMomentChipLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(row, id: \.self) { item in
                            content(item)
                        }
                    }
                }
            }
        }
    }

    private var rows: [[Item]] {
        stride(from: 0, to: items.count, by: 3).map { start in
            Array(items[start..<min(start + 3, items.count)])
        }
    }
}

private struct VoiceSearchListeningView: View {
    let topInset: CGFloat
    let transcript: String
    let statusText: String
    let isRecording: Bool
    let onBack: () -> Void
    let onToggleRecording: () -> Void
    @State private var isWaveAnimating = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: AppIcons.Navigation.back)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(LiquidGlassBackground(cornerRadius: 16, tone: .dark))
                    }
                    .buttonStyle(LiquidButtonPressStyle())

                    Spacer()
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
                .padding(.top, topInset + 2)

                Spacer()

                VStack(spacing: 16) {
                    if !transcript.isEmpty {
                        Text(transcript)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, UIConstants.Spacing.lg)
                    }

                    ZStack {
                        voiceWaveBackground

                        VStack(spacing: 14) {
                            ZStack {
                                Button(action: onToggleRecording) {
                                    ZStack {
                                        LiquidGlassCircleBackground(tone: .dark, isHighlighted: isRecording)
                                            .frame(width: 84, height: 84)

                                        Image(systemName: isRecording ? "stop.fill" : AppIcons.Action.mic)
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .buttonStyle(LiquidButtonPressStyle())
                            }

                            Text(statusText)
                                .font(.system(size: 18, weight: .medium))
                                .italic()
                                .foregroundStyle(Color.white.opacity(0.82))
                        }
                        .padding(.bottom, 54)
                    }
                    .frame(height: 270)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) {
                isWaveAnimating = true
            }
        }
    }

    private var voiceWaveBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color.clear, Color(hex: "18010C"), Color(hex: "06010B")],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color(hex: "FF5E00"))
                .blur(radius: 32)
                .frame(width: isWaveAnimating ? 285 : 238, height: isWaveAnimating ? 268 : 232)
                .offset(x: isWaveAnimating ? -44 : -98, y: isWaveAnimating ? 26 : 58)

            Circle()
                .fill(Color(hex: "F20E68"))
                .blur(radius: 38)
                .frame(width: isWaveAnimating ? 245 : 306, height: isWaveAnimating ? 238 : 268)
                .offset(x: isWaveAnimating ? 88 : 46, y: isWaveAnimating ? 34 : 60)

            Circle()
                .fill(Color(hex: "4A1BC7"))
                .blur(radius: 44)
                .frame(width: isWaveAnimating ? 306 : 250, height: isWaveAnimating ? 282 : 250)
                .offset(x: isWaveAnimating ? -12 : -40, y: isWaveAnimating ? 78 : 106)

            RoundedRectangle(cornerRadius: 160, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "FFB347"), Color(hex: "FF5E00"), Color(hex: "8424FF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 8
                )
                .frame(width: 420, height: 180)
                .offset(x: isWaveAnimating ? 22 : -18, y: isWaveAnimating ? 66 : 86)
                .blur(radius: 3)
        }
        .clipped()
    }
}

private struct VoiceSearchResultsView: View {
    let topInset: CGFloat
    let transcript: String
    @ObservedObject var viewModel: SearchViewModel
    let onBack: () -> Void
    let onSelectItem: (StorefrontItem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs),
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs),
        GridItem(.flexible(), spacing: UIConstants.Spacing.xs)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Results for \"\(transcript)\"")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.top, 10)
                            .padding(.horizontal, UIConstants.Spacing.lg)

                        resultContent
                    }
                    .padding(.bottom, viewModel.availableFilters.count > 1 ? 178 : 124)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if viewModel.availableFilters.count > 1 {
                    SearchFilterDock(
                        filters: Array(viewModel.availableFilters.prefix(4)),
                        selectedFilterID: viewModel.selectedFilterID,
                        onSelect: { filter in
                            viewModel.selectedFilterID = filter.id
                        }
                    )
                }

                voiceQueryBar
                    .padding(.horizontal, UIConstants.Spacing.lg)
            }
            .padding(.bottom, 14)
            .background(searchDockBackdrop(height: viewModel.availableFilters.count > 1 ? 166 : 112))
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: AppIcons.Navigation.back)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(LiquidButtonPressStyle())

            Spacer()
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
        .padding(.top, topInset + 2)
    }

    @ViewBuilder
    private var resultContent: some View {
        if viewModel.isLoading && viewModel.results.isEmpty {
            ProgressView()
                .tint(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
        } else if let errorMessage = viewModel.errorMessage, viewModel.results.isEmpty {
            ErrorView(title: AppStrings.Search.unavailableTitle, message: errorMessage, onRetry: nil)
                .padding(.horizontal, UIConstants.Spacing.lg)
        } else if viewModel.displayedResults.isEmpty {
            EmptyStateView(title: AppStrings.Search.noResults, message: transcript, systemImage: AppIcons.Navigation.search)
                .padding(.horizontal, UIConstants.Spacing.lg)
        } else {
            VStack(alignment: .leading, spacing: 24) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(viewModel.displayedResults.prefix(8))) { item in
                            SearchPosterCard(
                                item: item,
                                size: CGSize(width: 124, height: 186),
                                showsPlayIcon: false,
                                onSelect: onSelectItem
                            )
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(viewModel.displayedResults.dropFirst(min(3, viewModel.displayedResults.count)))) { item in
                        SearchPosterCard(
                            item: item,
                            size: CGSize(width: 124, height: 186),
                            showsPlayIcon: false,
                            onSelect: onSelectItem
                        )
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
            }
        }
    }

    private var voiceQueryBar: some View {
        HStack(spacing: 12) {
            Image(systemName: AppIcons.Navigation.search)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.88))

            Text(transcript)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.8))
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.74))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

private struct AISearchPromptView: View {
    let topInset: CGFloat
    @Binding var prompt: String
    let suggestions: [String]
    let onBack: () -> Void
    let onSelectSuggestion: (String) -> Void
    let onSubmit: (String) -> Void
    let onVoiceTap: () -> Void
    @FocusState private var isPromptFocused: Bool

    private let chipColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 6)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AISearchGradientBackdrop()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    AiSearchBackButton(onTap: onBack)
                    Spacer()
                    Text("Ai Search")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 46, height: 46)
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
                .padding(.top, topInset + 2)

                VStack(alignment: .leading, spacing: 13) {
                    Text("Discover with AI")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "7818B4"), .white, Color(hex: "FF5E00")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("What would you like to watch?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.82))

                    LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 10) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                onSelectSuggestion(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.62))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.white.opacity(0.06))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(LiquidButtonPressStyle())
                        }
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
                .padding(.top, 28)

                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: AppIcons.Navigation.search)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.48))

                    TextField("", text: $prompt, prompt: Text("Ask me anything about movies, TV shows, sports, or live events.").foregroundStyle(Color.white.opacity(0.42)))
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($isPromptFocused)
                        .foregroundStyle(.white)
                        .font(.system(size: 14, weight: .regular))
                        .onSubmit {
                            onSubmit(prompt)
                        }
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.black.opacity(0.74))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )

                Button(action: onVoiceTap) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                        Image(systemName: AppIcons.Action.mic)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 54, height: 54)
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
            .padding(.horizontal, UIConstants.Spacing.lg)
            .padding(.bottom, 18)
            .background(searchDockBackdrop(height: 112))
            .task {
                try? await Task.sleep(for: .milliseconds(150))
                isPromptFocused = true
            }
        }
    }
}

private struct AISearchTextResultsView: View {
    let topInset: CGFloat
    let query: String
    @ObservedObject var viewModel: SearchViewModel
    let onBack: () -> Void
    let onSelectItem: (StorefrontItem) -> Void
    let onFollowUpTap: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    private let followUps = [
        "More action thrillers",
        "Best chase sequences",
        "High-intensity stunt scenes",
        "Spy action clips",
        "Famous action moments",
        "Behind the scenes"
    ]

    private var displayItems: [StorefrontItem] {
        let candidates = viewModel.displayedResults.isEmpty ? viewModel.popularItems : viewModel.displayedResults
        return Array(candidates.prefix(6))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AISearchGradientBackdrop(topPadding: 270)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    AiSearchBackButton(onTap: onBack)
                    Spacer()
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
                .padding(.top, topInset + 2)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Results for \"\(query)\"")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, UIConstants.Spacing.lg)
                            .padding(.top, 16)

                        if viewModel.isLoading && viewModel.results.isEmpty {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(displayItems) { item in
                                    AISearchResultPosterCard(item: item, onSelect: onSelectItem)
                                }
                            }
                            .padding(.horizontal, UIConstants.Spacing.lg)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Explore related moments")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)

                            FlexibleChipFlow(items: followUps, onTap: onFollowUpTap)
                        }
                        .padding(.horizontal, UIConstants.Spacing.lg)
                    }
                    .padding(.bottom, viewModel.availableFilters.count > 1 ? 178 : 124)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if viewModel.availableFilters.count > 1 {
                    SearchFilterDock(
                        filters: Array(viewModel.availableFilters.prefix(4)),
                        selectedFilterID: viewModel.selectedFilterID,
                        onSelect: { filter in
                            viewModel.selectedFilterID = filter.id
                        }
                    )
                }

                aiQueryBar
                    .padding(.horizontal, UIConstants.Spacing.lg)
            }
            .padding(.bottom, 14)
            .background(searchDockBackdrop(height: viewModel.availableFilters.count > 1 ? 166 : 112))
        }
    }

    private var aiQueryBar: some View {
        HStack(spacing: 12) {
            Image(systemName: AppIcons.Navigation.search)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.88))

            Text(query)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.8))
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.74))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

private struct AISearchGradientBackdrop: View {
    var topPadding: CGFloat = 360

    var body: some View {
        VStack {
            Spacer(minLength: topPadding)
            LinearGradient(
                colors: [
                    Color(hex: "2D39A8").opacity(0.95),
                    Color(hex: "6E1D73").opacity(0.88),
                    Color(hex: "B03261").opacity(0.92)
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .blur(radius: 12)
        }
    }
}

private struct AiSearchBackButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: AppIcons.Navigation.back)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

private struct AISearchResultPosterCard: View {
    let item: StorefrontItem
    let onSelect: (StorefrontItem) -> Void

    var body: some View {
        Button {
            onSelect(item)
        } label: {
            ZStack {
                PosterImageView(
                    url: item.imageURL(for: "0-2x3", width: 360),
                    size: CGSize(width: 111, height: 197),
                    cornerRadius: 4
                )

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.15), Color.black.opacity(0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Image(systemName: AppIcons.Action.playCircle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white.opacity(0.96), .white.opacity(0.24))
            }
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

private struct FlexibleChipFlow: View {
    let items: [String]
    let onTap: (String) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 6)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button {
                    onTap(item)
                } label: {
                    Text(item)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.84))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
        }
    }
}

private func searchDockBackdrop(height: CGFloat) -> some View {
    ZStack(alignment: .bottom) {
        Rectangle()
            .fill(Color.black.opacity(0.34))
            .frame(height: max(height - 22, 80))
            .blur(radius: 12)

        LinearGradient(
            colors: [Color.black.opacity(0), Color.black.opacity(0.88), Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
    }
    .allowsHitTesting(false)
}

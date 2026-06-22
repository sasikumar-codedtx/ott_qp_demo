import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    let profileName: String
    let prefersVoiceAISearch: Bool
    let onSelectItem: (StorefrontItem) -> Void
    let onOpenHome: () -> Void
    let onOpenShorts: () -> Void
    let onOpenHot: () -> Void
    let onProfileTap: () -> Void
    @FocusState private var isSearchFocused: Bool
    @State private var aiOverlayMode: AISearchOverlayMode?
    @State private var aiQuery = ""
    @State private var aiTextPrompt = ""
    @State private var simulatedVoiceTask: Task<Void, Never>?

    private let mockedVoiceQuery = "Latest Hindi thrillers"
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

    private var showsBottomBar: Bool {
        !isSearchFocused && aiOverlayMode == nil
    }

    private var recommendedClips: [StorefrontItem] {
        Array(viewModel.popularItems.prefix(3))
    }

    private var relatedMomentChips: [String] {
        let source = viewModel.popularItems.isEmpty ? viewModel.results : viewModel.popularItems
        return Array(source.map(\.title).filter { !$0.isEmpty }.prefix(8))
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                searchHeader(topInset: proxy.safeAreaInsets.top)

                ZStack(alignment: .bottomTrailing) {
                    content
                    floatingButton
                }

                if showsBottomBar {
                    BottomNavigationBar(
                        selection: .search,
                        profileImageName: ProfileArtworkResolver.imageName(forName: profileName),
                        onHomeTap: onOpenHome,
                        onSearchTap: {},
                        onShortsTap: onOpenShorts,
                        onHotTap: onOpenHot,
                        onProfileTap: onProfileTap
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(searchBackground.ignoresSafeArea())
            .ignoresSafeArea(edges: .top)
            .safeAreaInset(edge: .bottom) {
                if aiOverlayMode == nil {
                    searchFieldDock
                        .padding(.horizontal, UIConstants.Spacing.lg)
                        .padding(.bottom, showsBottomBar ? 8 : 14)
                        .background(Color.black.opacity(0.001))
                }
            }

            if let aiOverlayMode {
                aiOverlay(mode: aiOverlayMode, topInset: proxy.safeAreaInsets.top)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(150))
            if aiOverlayMode == nil {
                isSearchFocused = true
            }
        }
        .onDisappear {
            simulatedVoiceTask?.cancel()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.normalizedQuery.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    searchSectionHeader(title: "Recommended Clips", showsChevron: true)
                        .padding(.horizontal, UIConstants.Spacing.lg)
                        .padding(.top, UIConstants.Spacing.xl - 2)

                    if recommendedClips.isEmpty {
                        EmptyStateView(title: AppStrings.Search.popular, message: AppStrings.Search.emptyPopular, systemImage: "sparkles.tv")
                            .padding(.horizontal, UIConstants.Spacing.lg)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: UIConstants.Spacing.xs) {
                                ForEach(recommendedClips) { item in
                                    SearchPosterCard(item: item, onSelect: onSelectItem)
                                }
                            }
                            .padding(.horizontal, UIConstants.Spacing.lg)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Explore related moments")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.96))

                        FlexibleMomentChipLayout(items: relatedMomentChips) { title in
                            momentChip(title)
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                }
                .padding(.bottom, 160)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.lg) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: UIConstants.Spacing.xs + 2) {
                            ForEach(SearchCategory.allCases) { category in
                                Button {
                                    viewModel.selectedCategory = category
                                } label: {
                                    Text(category.rawValue)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(viewModel.selectedCategory == category ? .black : .white.opacity(0.78))
                                        .padding(.horizontal, 18)
                                        .frame(height: 34)
                                        .background(
                                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.sm, style: .continuous)
                                                .fill(viewModel.selectedCategory == category ? .white : Color.white.opacity(0.08))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, UIConstants.Spacing.lg)
                    }
                    .padding(.top, UIConstants.Spacing.lg)

                    if viewModel.isLoading && viewModel.results.isEmpty {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.results.isEmpty {
                        ErrorView(title: AppStrings.Search.unavailableTitle, message: errorMessage, onRetry: nil)
                    } else if viewModel.displayedResults.isEmpty {
                        EmptyStateView(title: AppStrings.Search.noResults, message: viewModel.normalizedQuery, systemImage: AppIcons.Navigation.search)
                    } else {
                        let featureTitle = viewModel.displayedResults.first?.title ?? viewModel.normalizedQuery.capitalized

                        VStack(alignment: .leading, spacing: UIConstants.Spacing.xl - 4) {
                            SectionHeaderView(title: featureTitle)
                                .padding(.horizontal, UIConstants.Spacing.lg)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: UIConstants.Spacing.xs) {
                                    ForEach(Array(viewModel.displayedResults.prefix(8))) { item in
                                        SearchPosterCard(item: item, onSelect: onSelectItem)
                                    }
                                }
                                .padding(.horizontal, UIConstants.Spacing.lg)
                            }

                            SectionHeaderView(title: "\"\(featureTitle)\" From Movies")
                                .padding(.horizontal, UIConstants.Spacing.lg)

                            LazyVGrid(columns: columns, spacing: UIConstants.Spacing.xs) {
                                ForEach(Array(viewModel.displayedResults.dropFirst(min(6, viewModel.displayedResults.count)))) { item in
                                    SearchPosterCard(item: item, onSelect: onSelectItem)
                                }
                            }
                            .padding(.horizontal, UIConstants.Spacing.lg)
                        }
                    }
                }
                .padding(.bottom, 160)
            }
        }
    }

    private var searchBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "17111F"), Color(hex: "09080D"), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color(hex: "7A1E53").opacity(0.55))
                .blur(radius: 120)
                .frame(width: 280, height: 280)
                .offset(x: -110, y: -260)

            Circle()
                .fill(Color(hex: "35106D").opacity(0.58))
                .blur(radius: 120)
                .frame(width: 300, height: 300)
                .offset(x: 140, y: -260)
        }
    }

    private func searchHeader(topInset: CGFloat) -> some View {
        HStack {
            Button(action: onOpenHome) {
                Image(systemName: AppIcons.Navigation.back)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text(AppStrings.Search.placeholder)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 42, height: 42)
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
        .padding(.top, topInset + 10)
        .padding(.bottom, 8)
    }

    private var searchFieldDock: some View {
        SearchFieldView(
            text: $viewModel.query,
            isFocused: $isSearchFocused,
            placeholder: "Search Movies, Shows, Sports...",
            iconName: "magnifyingglass"
        )
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }

    private var floatingButton: some View {
        Button(action: beginAISearch) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "6B1F73"), Color(hex: "1B102A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )

                Circle()
                    .stroke(Color(hex: "F29B38"), lineWidth: 1.5)
                    .frame(width: 26, height: 26)

                Image(systemName: AppIcons.Action.mic)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: UIConstants.Size.floatingAction, height: UIConstants.Size.floatingAction)
            .padding(.trailing, UIConstants.Spacing.lg + 2)
            .padding(.bottom, 90)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func aiOverlay(mode: AISearchOverlayMode, topInset: CGFloat) -> some View {
        switch mode {
        case .voiceListening:
            VoiceSearchListeningView(
                topInset: topInset,
                transcript: aiQuery,
                onBack: closeAISearch
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
        simulatedVoiceTask?.cancel()
        isSearchFocused = false
        aiQuery = ""
        aiTextPrompt = ""

        withAnimation(.easeInOut(duration: 0.24)) {
            aiOverlayMode = .textPrompt
        }
    }

    private func beginVoiceSearch() {
        simulatedVoiceTask?.cancel()
        isSearchFocused = false
        aiQuery = ""

        withAnimation(.easeInOut(duration: 0.24)) {
            aiOverlayMode = .voiceListening
        }

        simulatedVoiceTask = Task {
            try? await Task.sleep(for: .milliseconds(1400))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                aiQuery = mockedVoiceQuery
            }

            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                viewModel.query = mockedVoiceQuery
                withAnimation(.easeInOut(duration: 0.24)) {
                    aiOverlayMode = .voiceResults
                }
            }
        }
    }

    private func submitTextAISearch(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        simulatedVoiceTask?.cancel()
        aiQuery = trimmed
        aiTextPrompt = trimmed
        viewModel.query = trimmed

        withAnimation(.easeInOut(duration: 0.24)) {
            aiOverlayMode = .textResults
        }
    }

    private func closeAISearch() {
        simulatedVoiceTask?.cancel()
        simulatedVoiceTask = nil
        withAnimation(.easeInOut(duration: 0.22)) {
            aiOverlayMode = nil
        }
    }
}

private enum AISearchOverlayMode {
    case voiceListening
    case voiceResults
    case textPrompt
    case textResults
}

private struct SearchPosterCard: View {
    let item: StorefrontItem
    let onSelect: (StorefrontItem) -> Void

    var body: some View {
        Button {
            onSelect(item)
        } label: {
            ZStack {
                PosterImageView(
                    url: item.imageURL(for: "0-2x3", width: 480),
                    size: CGSize(width: 112, height: 168),
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

                Image(systemName: AppIcons.Action.playCircle)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92), .white.opacity(0.22))
            }
        }
        .buttonStyle(.plain)
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
    let onBack: () -> Void

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
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
                .padding(.top, topInset + 12)

                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 94, height: 94)

                Spacer()

                VStack(spacing: 16) {
                    if !transcript.isEmpty {
                        Text(transcript)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    ZStack {
                        voiceWaveBackground

                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                                    .frame(width: 84, height: 84)

                                HStack(spacing: 5) {
                                    ForEach(0..<6, id: \.self) { _ in
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                            }

                            Text("Listening...")
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
                .frame(width: 250, height: 250)
                .offset(x: -80, y: 44)

            Circle()
                .fill(Color(hex: "F20E68"))
                .blur(radius: 38)
                .frame(width: 290, height: 260)
                .offset(x: 58, y: 48)

            Circle()
                .fill(Color(hex: "4A1BC7"))
                .blur(radius: 44)
                .frame(width: 260, height: 260)
                .offset(x: -24, y: 90)

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
                .offset(y: 76)
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

                        categoryBar

                        resultContent
                    }
                    .padding(.bottom, 120)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            voiceQueryBar
                .padding(.horizontal, UIConstants.Spacing.lg)
                .padding(.bottom, 14)
                .background(Color.black.opacity(0.001))
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
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, UIConstants.Spacing.lg)
        .padding(.top, topInset + 12)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(SearchCategory.allCases) { category in
                    Button {
                        viewModel.selectedCategory = category
                    } label: {
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(viewModel.selectedCategory == category ? .white : Color.white.opacity(0.56))
                            .padding(.horizontal, 16)
                            .frame(height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(viewModel.selectedCategory == category ? Color.white.opacity(0.08) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, UIConstants.Spacing.lg)
        }
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
                    HStack(spacing: UIConstants.Spacing.xs) {
                        ForEach(Array(viewModel.displayedResults.prefix(8))) { item in
                            SearchPosterCard(item: item, onSelect: onSelectItem)
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                }

                LazyVGrid(columns: columns, spacing: UIConstants.Spacing.xs) {
                    ForEach(Array(viewModel.displayedResults.dropFirst(min(3, viewModel.displayedResults.count)))) { item in
                        SearchPosterCard(item: item, onSelect: onSelectItem)
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
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
                .padding(.top, topInset + 12)

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
                            .buttonStyle(.plain)
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
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.white.opacity(0.72), lineWidth: 1)
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
                .buttonStyle(.plain)
            }
            .padding(.horizontal, UIConstants.Spacing.lg)
            .padding(.bottom, 18)
            .background(Color.black.opacity(0.001))
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
                .padding(.top, topInset + 12)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(explanationText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.82))
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
                    .padding(.bottom, 70)
                }
            }
        }
    }

    private var explanationText: String {
        "I found titles and moments related to \(query). Here are the most relevant Sony LIV clips and scenes."
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
        .buttonStyle(.plain)
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
        .buttonStyle(.plain)
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
                .buttonStyle(.plain)
            }
        }
    }
}

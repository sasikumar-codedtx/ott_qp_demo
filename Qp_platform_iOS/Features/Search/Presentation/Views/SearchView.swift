import SwiftUI
import Translation

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    let profileName: String
    let prefersVoiceAISearch: Bool
    let onBack: () -> Void
    let onOpenAISearch: (() -> Void)?
    let onSelectItem: (StorefrontItem) -> Void
    @FocusState private var isSearchFocused: Bool
    @State private var searchInput = ""   // local — never bound to viewModel.query during typing
    @State private var aiOverlayMode: AISearchOverlayMode?
    @State private var aiQuery = ""
    @State private var aiSearchQuery = ""
    @State private var aiTextPrompt = ""
    @State private var voiceSubmitTask: Task<Void, Never>?
    @State private var isKeyboardVisible = false
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var isTranslatingInlineVoice = false
    @State private var inlineVoicePendingTranslation: PendingVoiceTranslation?
    @State private var inlineVoiceTranslationConfig: TranslationSession.Configuration?
    @State private var inlineVoiceTranslationError: String?

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

    private var shouldShowResultFilters: Bool {
        !viewModel.normalizedQuery.isEmpty && viewModel.availableFilters.count > 1
    }

    private var searchDockFilters: [SearchFilter] {
        // Show filters only after a search has been submitted (viewModel.normalizedQuery),
        // not while the user is still typing (searchInput may differ).
        if !viewModel.normalizedQuery.isEmpty {
            return Array(viewModel.availableFilters.prefix(4))
        }
        return []
    }

    private var showsSearchDockFilters: Bool {
        searchDockFilters.count > 1
    }

    private var inlineVoiceStatusText: String {
        if let inlineVoiceTranslationError { return inlineVoiceTranslationError }
        if isTranslatingInlineVoice { return "Translating Hindi to English..." }
        return speechService.statusText
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Anchor the ZStack to full screen so it never collapses to zero
                // when content is empty — prevents the dock jumping to the top.
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                content
                    .padding(.top, proxy.safeAreaInsets.top + 28)

                if isSearchFocused && aiOverlayMode == nil {
                    ZStack {
                        KeyboardOverlayBackdropView()

                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isSearchFocused = false
                            }
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                }
            }
            .background(searchBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if aiOverlayMode == nil {
                    bottomSearchDock(bottomInset: proxy.safeAreaInsets.bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            if let aiOverlayMode {
                aiOverlay(mode: aiOverlayMode, topInset: proxy.safeAreaInsets.top, bottomInset: proxy.safeAreaInsets.bottom)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .onAppear {
            // Sync local field to the viewModel's current query (handles screen re-entry)
            searchInput = viewModel.query
        }
        .onDisappear {
            voiceSubmitTask?.cancel()
            speechService.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .onChange(of: speechService.transcript) { _, transcript in
            scheduleVoiceSearch(for: transcript)
        }
        .translationTask(inlineVoiceTranslationConfig) { session in
            await translateInlinePendingVoiceSearch(with: session)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.results.isEmpty && viewModel.momentResults.isEmpty {
            SearchLoadingStateView()
        } else if !viewModel.displayedResults.isEmpty || !viewModel.momentResults.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Rail 1 — content (moment=false): horizontal scroll
                    if !viewModel.displayedResults.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeaderView(title: "\(viewModel.displaySearchTerm) Contents")
                                .padding(.horizontal, UIConstants.Spacing.lg)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.displayedResults) { item in
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

                    // Rail 2 — moments (moment=true): vertical grid
                    if !viewModel.momentResults.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeaderView(title: "\(viewModel.displaySearchTerm) Moments")
                                .padding(.horizontal, UIConstants.Spacing.lg)

                            SearchRecommendedClipGrid(
                                items: viewModel.momentResults,
                                onSelect: onSelectItem
                            )
                            .padding(.horizontal, UIConstants.Spacing.lg)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, searchDockReservedHeight + 20)
                .animation(.easeOut(duration: 0.25), value: searchDockReservedHeight)
            }
            .simultaneousGesture(TapGesture().onEnded { isSearchFocused = false })
            .scrollDismissesKeyboard(.interactively)
        } else if !viewModel.isLoading && !viewModel.normalizedQuery.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.28))
                Text("No relevant data available")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.54))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, searchDockReservedHeight)
        }
    }

    private var searchBackground: some View {
        ZStack {
            Color.black

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

    private func bottomSearchDock(bottomInset: CGFloat) -> some View {
        VStack(spacing: 14) {
            if !viewModel.popularSuggestions.isEmpty && searchInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppStrings.Search.popular)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.54))
                        .padding(.horizontal, UIConstants.Spacing.lg)

                    SuggestionChipFlow(
                        suggestions: viewModel.popularSuggestions,
                        maxRows: 2,
                        maxItemsPerRow: 3,
                        horizontalPadding: UIConstants.Spacing.lg
                    ) { suggestion in
                        searchInput = suggestion
                        submitSearchInput()
                    }
                }
            }

            if showsSearchDockFilters {
                SearchFilterDock(
                    filters: searchDockFilters,
                    selectedFilterID: viewModel.selectedFilterID,
                    onSelect: { filter in
                        viewModel.selectFilter(filter)
                        isSearchFocused = false
                    }
                )
                .padding(.horizontal, UIConstants.Spacing.lg)
            }

            HStack(spacing: 12) {
                SearchFieldView(
                    text: $searchInput,
                    isFocused: $isSearchFocused,
                    placeholder: "Search Movies, Shows, Sports...",
                    iconName: "magnifyingglass",
                    onSubmit: {
                        submitSearchInput()
                    }
                )
                .frame(height: 54)

                if isSearchFocused {
                    let hasText = !searchInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    Button(action: submitSearchInput) {
                        ZStack {
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.capsule, style: .continuous)
                                .fill(
                                    hasText
                                        ? LinearGradient(
                                            colors: [Color(hex: "FF6105"), Color(hex: "D05AFF"), Color(hex: "7B2CFF")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                          )
                                        : LinearGradient(
                                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.12)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                          )
                                )
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: UIConstants.Size.textFieldHeight, height: UIConstants.Size.textFieldHeight)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                    .disabled(!hasText)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button(action: openAISearch) {
                        Image("mic")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 54, height: 54)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.18), value: isSearchFocused)
            .padding(.horizontal, UIConstants.Spacing.lg)
        }
        .padding(.top, 8)
        .padding(.bottom, searchDockBottomPadding(bottomInset: bottomInset))
        .background(searchDockBackdrop(height: searchDockBackdropHeight, isKeyboardVisible: isKeyboardVisible))
    }

    private var showsSuggestions: Bool {
        !viewModel.popularSuggestions.isEmpty && searchInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var searchDockReservedHeight: CGFloat {
        if showsSuggestions { return showsSearchDockFilters ? 258 : 208 }
        return showsSearchDockFilters ? 178 : 128
    }

    private var searchDockBackdropHeight: CGFloat {
        let suggestionExtra: CGFloat = showsSuggestions ? 80 : 0
        if showsSearchDockFilters {
            return (isKeyboardVisible ? 226 : 178) + suggestionExtra
        }
        return (isKeyboardVisible ? 190 : 130) + suggestionExtra
    }

    private func searchDockBottomPadding(bottomInset: CGFloat) -> CGFloat {
        isKeyboardVisible ? 8 : max(bottomInset, 12) + 12
    }

    private func submitSearchInput() {
        let trimmed = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.query = trimmed
        viewModel.submitSearch()
        isSearchFocused = false
    }

    private func openAISearch() {
        SearchHaptics.micTap()
        isSearchFocused = false
        if let onOpenAISearch {
            onOpenAISearch()
        } else {
            beginVoiceSearch()
        }
    }

    @ViewBuilder
    private func aiOverlay(mode: AISearchOverlayMode, topInset: CGFloat, bottomInset: CGFloat) -> some View {
        switch mode {
        case .voiceListening:
            ZStack(alignment: .top) {
                VoiceSearchListeningView(
                    transcript: speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines),
                    statusText: inlineVoiceStatusText,
                    isRecording: speechService.isRecording,
                    onToggleRecording: toggleVoiceRecording
                )

                AISearchTopBar(title: "AI Search", topInset: topInset, onBack: closeAISearch) {
                    voiceOverlayLanguageMenu
                }
            }
        case .voiceResults:
            VoiceSearchResultsView(
                topInset: topInset,
                transcript: aiQuery,
                searchQuery: aiSearchQuery,
                viewModel: viewModel,
                onBack: closeAISearch,
                onSelectItem: onSelectItem
            )
        case .textPrompt:
            AISearchPromptView(
                topInset: topInset,
                bottomInset: bottomInset,
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

    private var voiceOverlayLanguageMenu: some View {
        Menu {
            ForEach(SupportedSpeechLanguage.allCases) { language in
                Button {
                    changeVoiceLanguage(language)
                } label: {
                    HStack {
                        Text(language.isAvailableForSpeechRecognition ? language.menuTitle : "\(language.menuTitle) unavailable")
                        if speechService.selectedLanguage == language {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .disabled(!language.isAvailableForSpeechRecognition)
            }
        } label: {
            HStack(spacing: 8) {
                Text(speechService.selectedLanguage.menuTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.13))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            )
        }
    }

    private func beginTextAISearch() {
        isSearchFocused = false
        aiQuery = ""
        aiSearchQuery = ""
        aiTextPrompt = ""

        withAnimation(.easeInOut(duration: 0.24)) {
            aiOverlayMode = .textPrompt
        }
    }

    private func beginVoiceSearch() {
        SearchHaptics.micTap()
        voiceSubmitTask?.cancel()
        isSearchFocused = false
        aiQuery = ""
        aiSearchQuery = ""
        speechService.reset()
        isTranslatingInlineVoice = false
        inlineVoicePendingTranslation = nil
        inlineVoiceTranslationError = nil

        withAnimation(.easeInOut(duration: 0.24)) {
            aiOverlayMode = .voiceListening
        }

        Task {
            let isReady = await speechService.prepareSession()
            guard isReady else { return }
            try? await Task.sleep(for: .milliseconds(450))
            await speechService.start()
            SearchHaptics.recordingStarted()
        }
    }

    private func changeVoiceLanguage(_ language: SupportedSpeechLanguage) {
        speechService.setLanguage(language)
        Task {
            let isReady = await speechService.prepareSession()
            guard isReady else { return }
            try? await Task.sleep(for: .milliseconds(220))
            await speechService.start()
            SearchHaptics.recordingStarted()
        }
    }

    private func toggleVoiceRecording() {
        if speechService.isRecording {
            speechService.stop()
            SearchHaptics.recordingFinished()
            submitVoiceSearchIfPossible(speechService.transcript)
        } else {
            isTranslatingInlineVoice = false
            inlineVoicePendingTranslation = nil
            inlineVoiceTranslationError = nil
            SearchHaptics.micTap()
            Task {
                let isReady = await speechService.prepareSession()
                guard isReady else { return }
                try? await Task.sleep(for: .milliseconds(220))
                await speechService.start()
                SearchHaptics.recordingStarted()
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

        voiceSubmitTask?.cancel()
        let wasRecording = speechService.isRecording
        speechService.stop()
        if wasRecording {
            SearchHaptics.recordingFinished()
        }

        aiQuery = trimmed

        switch speechService.selectedLanguage {
        case .english:
            aiSearchQuery = trimmed
            withAnimation(.easeInOut(duration: 0.24)) {
                aiOverlayMode = .voiceResults
            }
            Task {
                try? await Task.sleep(for: .milliseconds(420))
                guard aiOverlayMode == .voiceResults else { return }
                viewModel.submitAIQuery(displayText: aiQuery, apiQuery: aiSearchQuery)
            }
        case .hindi:
            requestInlineHindiTranslation(for: trimmed)
        }
    }

    private func requestInlineHindiTranslation(for transcript: String) {
        inlineVoiceTranslationError = nil
        isTranslatingInlineVoice = true
        inlineVoicePendingTranslation = PendingVoiceTranslation(displayText: transcript)

        if inlineVoiceTranslationConfig == nil {
            inlineVoiceTranslationConfig = TranslationSession.Configuration(
                source: Locale.Language(identifier: "hi"),
                target: Locale.Language(identifier: "en")
            )
        } else {
            inlineVoiceTranslationConfig?.invalidate()
        }
    }

    private func translateInlinePendingVoiceSearch(with session: TranslationSession) async {
        guard let pending = inlineVoicePendingTranslation else { return }

        do {
            try await session.prepareTranslation()
            let response = try await session.translate(pending.displayText)
            await MainActor.run {
                isTranslatingInlineVoice = false
                inlineVoicePendingTranslation = nil
                inlineVoiceTranslationError = nil
                aiSearchQuery = response.targetText
                withAnimation(.easeInOut(duration: 0.24)) {
                    aiOverlayMode = .voiceResults
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(420))
                    guard aiOverlayMode == .voiceResults else { return }
                    viewModel.submitAIQuery(displayText: pending.displayText, apiQuery: response.targetText)
                }
            }
        } catch {
            await MainActor.run {
                isTranslatingInlineVoice = false
                inlineVoicePendingTranslation = nil
                aiSearchQuery = pending.displayText
                withAnimation(.easeInOut(duration: 0.24)) {
                    aiOverlayMode = .voiceResults
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(420))
                    guard aiOverlayMode == .voiceResults else { return }
                    viewModel.submitAIQuery(displayText: pending.displayText, apiQuery: pending.displayText)
                }
            }
        }
    }

    private func submitTextAISearch(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        aiQuery = trimmed
        aiTextPrompt = trimmed
        aiSearchQuery = trimmed
        viewModel.query = trimmed

        withAnimation(.easeInOut(duration: 0.24)) {
            aiOverlayMode = .textResults
        }
    }

    private func closeAISearch() {
        voiceSubmitTask?.cancel()
        voiceSubmitTask = nil
        speechService.reset()
        isTranslatingInlineVoice = false
        inlineVoicePendingTranslation = nil
        inlineVoiceTranslationError = nil
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

private enum SearchHaptics {
    static func micTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func recordingStarted() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func recordingFinished() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct AISearchVoiceRouteView: View {
    @ObservedObject var viewModel: SearchViewModel
    let onBack: () -> Void
    let onSubmit: (String, String) -> Void
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var voiceSubmitTask: Task<Void, Never>?
    @State private var startupRecoveryTask: Task<Void, Never>?
    @State private var hasStartedListening = false
    @State private var pendingTranslation: PendingVoiceTranslation?
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var isTranslating = false
    @State private var translationErrorMessage: String?

    private var displayTranscript: String { speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack(alignment: .top) {
            VoiceSearchListeningView(
                transcript: displayTranscript,
                statusText: translationStatusText,
                isRecording: speechService.isRecording,
                onToggleRecording: toggleRecording
            )

            GeometryReader { proxy in
                RouteNavigationBar(title: "AI Search", onBack: close) {
                    languageMenu
                }
                .padding(.top, proxy.safeAreaInsets.top)
                .frame(maxWidth: .infinity)
                .frame(height: proxy.safeAreaInsets.top + 58, alignment: .top)
                .ignoresSafeArea(edges: .top)
            }
            .allowsHitTesting(true)
            .frame(height: 120, alignment: .top)
        }
        .onAppear {
            guard !hasStartedListening else { return }
            hasStartedListening = true
            startListening(delay: .milliseconds(650), shouldRecoverIfSilent: true)
        }
        .onDisappear {
            voiceSubmitTask?.cancel()
            startupRecoveryTask?.cancel()
            speechService.stop()
        }
        .onChange(of: speechService.transcript) { _, transcript in
            scheduleSubmit(for: transcript)
        }
        .translationTask(translationConfiguration) { session in
            await translatePendingVoiceSearch(with: session)
        }
    }

    private var translationStatusText: String {
        if let translationErrorMessage {
            return translationErrorMessage
        }

        if isTranslating {
            return "Translating Hindi to English..."
        }

        return speechService.statusText
    }

    private var languageMenu: some View {
        Menu {
            ForEach(SupportedSpeechLanguage.allCases) { language in
                Button {
                    changeLanguage(language)
                } label: {
                    HStack {
                        Text(language.isAvailableForSpeechRecognition ? language.menuTitle : "\(language.menuTitle) unavailable")
                        if speechService.selectedLanguage == language {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .disabled(!language.isAvailableForSpeechRecognition)
            }
        } label: {
            HStack(spacing: 8) {
                Text(speechService.selectedLanguage.menuTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.13))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            )
        }
    }

    private func close() {
        voiceSubmitTask?.cancel()
        speechService.reset()
        onBack()
    }

    private func toggleRecording() {
        if speechService.isRecording {
            startupRecoveryTask?.cancel()
            speechService.stop()
            SearchHaptics.recordingFinished()
            submitIfPossible(speechService.transcript)
        } else {
            SearchHaptics.micTap()
            startListening(delay: .milliseconds(220), shouldRecoverIfSilent: true)
        }
    }

    private func changeLanguage(_ language: SupportedSpeechLanguage) {
        voiceSubmitTask?.cancel()
        startupRecoveryTask?.cancel()
        speechService.setLanguage(language)
        startListening(delay: .milliseconds(260), shouldRecoverIfSilent: true)
    }

    private func startListening(delay: Duration, shouldRecoverIfSilent: Bool) {
        startupRecoveryTask?.cancel()
        Task { @MainActor in
            let isReady = await speechService.prepareSession()
            guard isReady else { return }
            try? await Task.sleep(for: delay)
            await speechService.start()
            SearchHaptics.recordingStarted()
            guard shouldRecoverIfSilent else { return }

            startupRecoveryTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(2400))
                guard !Task.isCancelled,
                      speechService.isRecording,
                      speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return
                }

                speechService.stop()
                let isReady = await speechService.prepareSession()
                guard isReady else { return }
                try? await Task.sleep(for: .milliseconds(260))
                await speechService.start()
                SearchHaptics.recordingStarted()
            }
        }
    }

    private func scheduleSubmit(for transcript: String) {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        voiceSubmitTask?.cancel()
        voiceSubmitTask = Task {
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                submitIfPossible(trimmed)
            }
        }
    }

    private func submitIfPossible(_ transcript: String) {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        voiceSubmitTask?.cancel()
        let wasRecording = speechService.isRecording
        speechService.stop()
        if wasRecording {
            SearchHaptics.recordingFinished()
        }

        switch speechService.selectedLanguage {
        case .english:
            onSubmit(trimmed, trimmed)
        case .hindi:
            requestHindiTranslation(for: trimmed)
        }
    }

    private func requestHindiTranslation(for transcript: String) {
        translationErrorMessage = nil
        isTranslating = true
        pendingTranslation = PendingVoiceTranslation(displayText: transcript)

        if translationConfiguration == nil {
            translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: "hi"),
                target: Locale.Language(identifier: "en")
            )
        } else {
            translationConfiguration?.invalidate()
        }
    }

    private func translatePendingVoiceSearch(with session: TranslationSession) async {
        guard let pendingTranslation else { return }

        do {
            try await session.prepareTranslation()
            let response = try await session.translate(pendingTranslation.displayText)
            await MainActor.run {
                isTranslating = false
                self.pendingTranslation = nil
                translationErrorMessage = nil
                onSubmit(pendingTranslation.displayText, response.targetText)
            }
        } catch {
            await MainActor.run {
                isTranslating = false
                self.pendingTranslation = nil
                translationErrorMessage = nil
                onSubmit(pendingTranslation.displayText, pendingTranslation.displayText)
            }
        }
    }
}

private struct PendingVoiceTranslation: Equatable {
    let displayText: String
}

private struct SearchRecommendedClipGrid: View {
    let items: [StorefrontItem]
    let onSelect: (StorefrontItem) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 10) {
            ForEach(items) { item in
                GeometryReader { proxy in
                    SearchPosterCard(
                        item: item,
                        size: CGSize(width: proxy.size.width, height: proxy.size.width * 1.5),
                        showsPlayIcon: true,
                        onSelect: onSelect
                    )
                }
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
            }
        }
    }
}

private struct SearchPlaceholderView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: AppIcons.Navigation.search)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.72))

            Text("Search Sony LIV")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            Text("Type a movie, show, sport, or moment to load results from search.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.54))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SearchLoadingStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: AppIcons.Action.sparkles)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.46))

            HStack(spacing: 4) {
                Text("Searching Content")
                    .font(.system(size: 18, weight: .regular))
                    .italic()
                    .foregroundStyle(.white)

                Text("for you")
                    .font(.system(size: 18, weight: .regular))
                    .italic()
                    .foregroundStyle(Color.white.opacity(0.72))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 116)
    }
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

private struct SearchFilterDock: View {
    let filters: [SearchFilter]
    let selectedFilterID: String
    let onSelect: (SearchFilter) -> Void

    var body: some View {
        HStack(spacing: -1) {
            ForEach(Array(filters.enumerated()), id: \.element.id) { index, filter in
                let isFirst = index == 0
                let isLast  = index == filters.count - 1

                Button {
                    onSelect(filter)
                } label: {
                    Text(filter.title)
                        .font(.system(size: 12, weight: selectedFilterID == filter.id ? .semibold : .regular))
                        .tracking(0.48)
                        .foregroundStyle(selectedFilterID == filter.id ? .white : Color(hex: "F0F0F0").opacity(0.8))
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .contentShape(Rectangle())
                }
                .contentShape(Rectangle())
                .buttonStyle(LiquidButtonPressStyle())
                .background(filterChipSurface(isFirst: isFirst, isLast: isLast))
                .fixedSize()
            }
        }
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private func filterChipSurface(isFirst: Bool, isLast: Bool) -> some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius:    isFirst ? 300 : 0,
            bottomLeadingRadius: isFirst ? 300 : 0,
            bottomTrailingRadius: isLast ? 300 : 0,
            topTrailingRadius:    isLast ? 300 : 0,
            style: .continuous
        )
        shape.fill(.ultraThinMaterial)
            .overlay(shape.fill(Color.black.opacity(0.9)))
            .overlay(
                shape.fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.05), location: 0),
                            .init(color: Color(hex: "FF8100").opacity(0.05), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .overlay(shape.stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

private struct VoiceSearchListeningView: View {
    let transcript: String
    let statusText: String
    let isRecording: Bool
    let onToggleRecording: () -> Void
    @State private var wavePhase: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
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

                    ZStack(alignment: .bottom) {
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
                    .frame(height: 330)
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            withAnimation(.linear(duration: 5.4).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
    }

    private var voiceWaveBackground: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(hex: "13020B").opacity(0.68),
                    Color(hex: "08030B").opacity(0.96),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            AIWaveShape(phase: wavePhase, amplitude: 16, baseline: 0.48)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FF7A18").opacity(0.0),
                            Color(hex: "FF7A18").opacity(0.58),
                            Color(hex: "E248FF").opacity(0.48),
                            Color(hex: "4F7BFF").opacity(0.34)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .blur(radius: 18)
                .opacity(0.9)

            AIWaveShape(phase: wavePhase + .pi, amplitude: 12, baseline: 0.62)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "3B82F6").opacity(0.0),
                            Color(hex: "3B82F6").opacity(0.34),
                            Color(hex: "A855F7").opacity(0.5),
                            Color(hex: "FF5E00").opacity(0.28)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .blur(radius: 22)
                .opacity(0.74)

            Capsule(style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFB347"),
                            Color(hex: "FF5E00"),
                            Color(hex: "E64AFF"),
                            Color(hex: "3B82F6")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 3
                )
                .blur(radius: 7)
                .opacity(0.58)
                .frame(height: 108)
                .padding(.horizontal, -44)
                .offset(y: 82)

            RadialGradient(
                colors: [
                    Color(hex: "FF9F1C").opacity(0.24),
                    Color(hex: "B026FF").opacity(0.14),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 8,
                endRadius: 240
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .mask(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.45), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .compositingGroup()
        .clipped(antialiased: false)
    }
}

private struct AIWaveShape: Shape {
    var phase: CGFloat
    let amplitude: CGFloat
    let baseline: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseY = rect.height * baseline
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: baseY))

        let step: CGFloat = 6
        var x: CGFloat = 0
        while x <= rect.width + step {
            let progress = x / max(rect.width, 1)
            let primary = sin(progress * .pi * 2 + phase) * amplitude
            let secondary = sin(progress * .pi * 4 + phase * 0.62) * amplitude * 0.34
            path.addLine(to: CGPoint(x: x, y: baseY + primary + secondary))
            x += step
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

private struct VoiceSearchResultsView: View {
    let topInset: CGFloat
    let transcript: String
    let searchQuery: String
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
                AISearchTopBar(title: "AI Search", topInset: topInset, onBack: onBack)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Results for \"\(transcript)\"")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.top, 18)
                            .padding(.horizontal, UIConstants.Spacing.lg)

                        if searchQuery.caseInsensitiveCompare(transcript) != .orderedSame {
                            Text("Searching in English: \(searchQuery)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.62))
                                .padding(.horizontal, UIConstants.Spacing.lg)
                        }

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
                            viewModel.selectFilter(filter)
                        }
                    )
                    .padding(.horizontal, UIConstants.Spacing.lg)
                }

                voiceQueryBar
                    .padding(.horizontal, UIConstants.Spacing.lg)
            }
            .padding(.bottom, 14)
            .background(searchDockBackdrop(height: viewModel.availableFilters.count > 1 ? 166 : 112))
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
    let bottomInset: CGFloat
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
                AISearchTopBar(title: "AI Search", topInset: topInset, onBack: onBack)

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
            .padding(.bottom, max(bottomInset, 8))
            .background {
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Color.black
                        .frame(height: max(bottomInset, 0) + 16)
                }
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
            }
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
        Array(viewModel.displayedResults.prefix(6))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AISearchGradientBackdrop(topPadding: 270)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                AISearchTopBar(title: "AI Search", topInset: topInset, onBack: onBack)

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
                            viewModel.selectFilter(filter)
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

private struct AISearchTopBar<Trailing: View>: View {
    let title: String?
    let topInset: CGFloat
    let onBack: () -> Void
    @ViewBuilder let trailing: Trailing

    init(
        title: String? = nil,
        topInset: CGFloat,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.topInset = topInset
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            if let title {
                NavigationChromeTitle(title: title)
                    .frame(maxWidth: 220)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                AiSearchBackButton(onTap: onBack)

                Spacer()

                trailing
                    .frame(minWidth: 45.5, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, topInset)
        .frame(height: topInset + 58, alignment: .bottom)
    }
}

private struct AiSearchBackButton: View {
    let onTap: () -> Void

    var body: some View {
        NavigationChromeButton(icon: AppIcons.Navigation.back, action: onTap)
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

private func searchDockBackdrop(height: CGFloat, isKeyboardVisible: Bool = false) -> some View {
    ZStack(alignment: .bottom) {
        Rectangle()
            .fill(Color.black.opacity(isKeyboardVisible ? 0.3 : 0.34))
            .frame(height: max(height - 22, 80))
            .blur(radius: isKeyboardVisible ? 26 : 12)

        LinearGradient(
            colors: [
                Color.black.opacity(0),
                Color.black.opacity(isKeyboardVisible ? 0.5 : 0.82),
                Color.black.opacity(isKeyboardVisible ? 0.82 : 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
    }
    .allowsHitTesting(false)
}

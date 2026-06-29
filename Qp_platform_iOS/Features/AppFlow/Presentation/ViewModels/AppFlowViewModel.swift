import Combine
import Foundation

@MainActor
final class AppFlowViewModel: ObservableObject {
    enum RootScreen {
        case splash
        case login
        case profileSelection
        case main
    }

    enum MainTab {
        case storefront
        case search
        case shorts
        case hot
    }

    enum ProfileEditorRoute: Hashable {
        case createNew
        case editExisting(Profile)
    }

    enum AvatarPickerRoute: Hashable {
        case createNew
        case editExisting
    }

    enum Route: Hashable {
        case otp
        case search
        case aiSearch
        case profileEditor(ProfileEditorRoute)
        case avatarPicker(AvatarPickerRoute)
        case profileHome
        case settings
        case storefrontTab(StorefrontTab)
        case detail(StorefrontItem)
        case sectionBrowse(StorefrontSection, QuickplayCohort)
        case collectionBrowse(StorefrontItem, QuickplayCohort)
    }

    @Published var rootScreen: RootScreen = .splash
    @Published var mainTab: MainTab = .storefront
    @Published var navigationPath: [Route] = []
    @Published private(set) var activeProfile: Profile?
    @Published var prefersVoiceAISearch = true
    @Published var activePlaybackContent: QuickplayPlaybackContent?
    @Published var playerEpisodes: [StorefrontItem] = []
    @Published var playerSeasons: [ContentSeason] = []
    @Published var cohortOverrideToast: String?
    let playerEngine = QuickplayPlayerEngine()

    let authViewModel: AuthViewModel
    let profileSelectionViewModel: ProfileSelectionViewModel
    let profileEditorViewModel: ProfileEditorViewModel
    let profileHubViewModel: ProfileHubViewModel
    let storefrontViewModel: StorefrontViewModel
    let hotStorefrontViewModel: StorefrontViewModel
    let storefrontSectionBrowseViewModel: StorefrontSectionBrowseViewModel
    let searchViewModel: SearchViewModel
    let shortsViewModel: ShortsFeedViewModel
    let detailViewModel: ContentDetailViewModel

    private let profileRepository: ProfileRepository
    private var hasStarted = false

    convenience init() {
        self.init(container: .shared)
    }

    init(container: AppContainer) {
        profileRepository = container.profileRepository

        authViewModel = AuthViewModel(
            requestOTPUseCase: RequestOTPUseCase(repository: container.authRepository),
            verifyOTPUseCase: VerifyOTPUseCase(repository: container.authRepository)
        )

        profileSelectionViewModel = ProfileSelectionViewModel(
            getProfilesUseCase: GetProfilesUseCase(repository: container.profileRepository)
        )

        profileEditorViewModel = ProfileEditorViewModel(
            repository: container.profileRepository,
            saveProfileUseCase: SaveProfileUseCase(repository: container.profileRepository)
        )

        profileHubViewModel = ProfileHubViewModel(
            useCase: GetProfileHomeUseCase(repository: container.profileHubRepository)
        )

        storefrontViewModel = StorefrontViewModel(
            initialUseCase: GetInitialStorefrontUseCase(repository: container.storefrontRepository),
            pageUseCase: GetStorefrontPageUseCase(repository: container.storefrontRepository)
        )

        hotStorefrontViewModel = StorefrontViewModel(
            initialUseCase: GetInitialStorefrontUseCase(repository: container.storefrontRepository),
            pageUseCase: GetStorefrontPageUseCase(repository: container.storefrontRepository)
        )

        storefrontSectionBrowseViewModel = StorefrontSectionBrowseViewModel(
            useCase: GetStorefrontSectionPageUseCase(repository: container.storefrontRepository)
        )

        searchViewModel = SearchViewModel(
            useCase: SearchContentUseCase(repository: container.searchRepository)
        )

        shortsViewModel = ShortsFeedViewModel(
            useCase: GetShortsBatchUseCase(repository: container.shortsRepository)
        )

        detailViewModel = ContentDetailViewModel(
            detailUseCase: GetContentDetailUseCase(repository: container.contentDetailRepository),
            recommendationsUseCase: GetRecommendationsUseCase(repository: container.contentDetailRepository),
            momentsUseCase: GetContentMomentsUseCase(repository: container.contentDetailRepository),
            episodesUseCase: GetContentEpisodesUseCase(repository: container.contentDetailRepository)
        )
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        prefersVoiceAISearch = await DemoSessionStore.shared.currentPrefersVoiceAISearch()
        try? await Task.sleep(for: .seconds(1.2))
        if await DemoSessionStore.shared.hasCompletedLogin() {
            // Ensure profiles for the stored phone number are in memory before loading.
            AppContainer.shared.reloadProfilesForStoredPhone()
            await profileSelectionViewModel.load()
            rootScreen = .profileSelection
        } else {
            rootScreen = .login
        }
    }

    func submitPhoneNumber() async {
        if await authViewModel.requestOTP() {
            push(.otp)
        }
    }

    func verifyOTP() async -> Bool {
        await authViewModel.verifyOTP()
    }

    func finishVerifiedSignIn() async {
        AppContainer.shared.switchAccount(phoneNumber: authViewModel.phoneNumber)
        await DemoSessionStore.shared.setHasCompletedLogin(true)
        await profileSelectionViewModel.load()
        navigationPath.removeAll()
        rootScreen = .profileSelection
    }

    func backToLogin() {
        authViewModel.resetOTPState()
        rootScreen = .login
        popRoute()
    }

    func selectProfile(_ profile: Profile) {
        activeProfile = profile
        storefrontViewModel.applyProfile(profile, forceReset: true)
        hotStorefrontViewModel.applyProfile(profile, forceReset: true)

        Task {
            let selectedCohort = profile.cohort
            let selectedPreference = selectedCohort.defaultPreference
            await DemoSessionStore.shared.setActiveProfileContext(
                profileID: profile.id,
                cohort: selectedCohort,
                preference: selectedPreference,
                storefrontPolicy: profile.storefrontPolicy,
                isKidsProfile: profile.isKidsProfile
            )
            navigationPath.removeAll()
            mainTab = .storefront
            rootScreen = .main
            await storefrontViewModel.reloadInitial(force: true)
            await hotStorefrontViewModel.reloadInitial(force: true)
        }
    }

    func openProfileEditor(_ profile: Profile?) {
        Task {
            if let profile {
                await profileEditorViewModel.prepareForEdit(profile: profile)
                await MainActor.run {
                    push(.profileEditor(.editExisting(profile)))
                }
                return
            }

            await profileEditorViewModel.prepareForCreate()
            await MainActor.run {
                push(.avatarPicker(.createNew))
            }
        }
    }

    func saveProfile() {
        Task {
            let isCreatingProfile = profileEditorViewModel.mode == .createNew
            let sourceProfileID = profileEditorViewModel.draft.sourceID
            let previousProfile = profileSelectionViewModel.profiles.first { $0.id == sourceProfileID }
            let saved = await profileEditorViewModel.save()
            guard let saved else { return }
            let didChangeCohort = previousProfile?.cohort != saved.cohort
            if isCreatingProfile || didChangeCohort {
                await DemoSessionStore.shared.resetPreferenceHistory(for: saved.id)
            }
            await profileSelectionViewModel.load()
            await MainActor.run {
                if isCreatingProfile {
                    selectProfile(saved)
                    return
                }

                if activeProfile?.id == saved.id {
                    activeProfile = saved
                    switchActiveProfileAndOpenStorefront(saved)
                    return
                }

                navigationPath.removeAll()
                rootScreen = .profileSelection
            }
        }
    }

    func deleteProfile() {
        Task {
            let didDelete = await profileEditorViewModel.deleteCurrentProfile()
            guard didDelete else { return }
            await profileSelectionViewModel.load()
            await MainActor.run {
                if let activeProfile, !profileSelectionViewModel.profiles.contains(where: { $0.id == activeProfile.id }) {
                    self.activeProfile = nil
                }
                navigationPath.removeAll()
                rootScreen = .profileSelection
            }
        }
    }

    func openAvatarPicker() {
        push(.avatarPicker(.editExisting))
    }

    func closeAvatarPicker() {
        popRoute()
    }

    func continueFromAvatarPicker() {
        guard let route = navigationPath.last else { return }

        switch route {
        case .avatarPicker(.createNew):
            replaceTopRoute(with: .profileEditor(.createNew))
        case .avatarPicker(.editExisting):
            popRoute()
        default:
            break
        }
    }

    func openSearch() {
        Task {
            searchViewModel.present()
            push(.search)
        }
    }

    func openAISearch() {
        push(.aiSearch)
    }

    func completeAISearch(displayText: String, apiQuery: String) {
        searchViewModel.submitAIQuery(displayText: displayText, apiQuery: apiQuery)
        popRoute()
    }

    func openShorts() {
        navigationPath.removeAll()
        mainTab = .shorts
    }

    func openProfileHome() {
        let profile = activeProfile ?? profileSelectionViewModel.defaultEditableProfile
        profileHubViewModel.present(profile: profile, seedItems: storefrontViewModel.searchSeedItems)
        push(.profileHome)
    }

    func backFromProfileHome() {
        popRoute()
    }

    func openSettings() {
        push(.settings)
    }

    func backFromSettings() {
        popRoute()
    }

    func openProfileSelection() {
        Task {
            await profileSelectionViewModel.load()
            await MainActor.run {
                navigationPath.removeAll()
                rootScreen = .profileSelection
            }
        }
    }

    func signOut() {
        authViewModel.resetOTPState()
        activeProfile = nil
        storefrontViewModel.applyProfile(nil)
        hotStorefrontViewModel.applyProfile(nil)
        Task {
            await DemoSessionStore.shared.clearActiveProfileContext()
        }
        navigationPath.removeAll()
        mainTab = .storefront
        rootScreen = .login
        // Clear in-memory profiles so a different user doesn't see them
        // before reloadForCurrentPhone() is called on next sign-in.
        AppContainer.shared.clearInMemoryProfiles()
    }

    func setPrefersVoiceAISearch(_ prefersVoice: Bool) {
        prefersVoiceAISearch = prefersVoice
        Task {
            await DemoSessionStore.shared.setPrefersVoiceAISearch(prefersVoice)
        }
    }

    func openStorefront() {
        navigationPath.removeAll()
        mainTab = .storefront
    }

    func switchActiveProfile(_ profile: Profile) {
        activeProfile = profile
        Task {
            let selectedCohort = profile.cohort
            let selectedPreference = selectedCohort.defaultPreference
            await DemoSessionStore.shared.setActiveProfileContext(
                profileID: profile.id,
                cohort: selectedCohort,
                preference: selectedPreference,
                storefrontPolicy: profile.storefrontPolicy,
                isKidsProfile: profile.isKidsProfile
            )
            storefrontViewModel.applyProfile(profile, forceReset: true)
            hotStorefrontViewModel.applyProfile(profile, forceReset: true)
            await storefrontViewModel.reloadInitial(force: true)
            await hotStorefrontViewModel.reloadInitial(force: true)
            profileHubViewModel.present(profile: profile, seedItems: storefrontViewModel.searchSeedItems)
        }
    }

    func switchActiveProfileAndOpenStorefront(_ profile: Profile) {
        activeProfile = profile
        storefrontViewModel.applyProfile(profile, forceReset: true)
        hotStorefrontViewModel.applyProfile(profile, forceReset: true)

        Task {
            let selectedCohort = profile.cohort
            let selectedPreference = selectedCohort.defaultPreference
            await DemoSessionStore.shared.setActiveProfileContext(
                profileID: profile.id,
                cohort: selectedCohort,
                preference: selectedPreference,
                storefrontPolicy: profile.storefrontPolicy,
                isKidsProfile: profile.isKidsProfile
            )
            navigationPath.removeAll()
            mainTab = .storefront
            rootScreen = .main
            await storefrontViewModel.reloadInitial(force: true)
            await hotStorefrontViewModel.reloadInitial(force: true)
            profileHubViewModel.present(profile: profile, seedItems: storefrontViewModel.searchSeedItems)
        }
    }

    func openHotTab() {
        navigationPath.removeAll()
        mainTab = .hot
    }

    func openStorefrontTab(_ tab: StorefrontTab) {
        mainTab = .storefront
        push(.storefrontTab(tab))
    }

    func openContent(item: StorefrontItem) {
        Task {
            await DemoSessionStore.shared.recordContentSelection(item)
        }

        switch ContentNavigationPolicy.destination(for: item) {
        case .detail:
            openDetail(item: item)
        case .player:
            openPlayerBackedContent(item)
        case .collection:
            openCollectionBrowse(item: item, cohort: storefrontViewModel.activeCohort)
        case .unsupported:
            if item.canOpenDetail {
                openDetail(item: item)
            } else {
                openPlayerBackedContent(item)
            }
        }
    }

    private func persistCohortOverride(_ cohort: QuickplayCohort) async throws -> Profile? {
        guard let activeProfile else { return nil }
        let updatedProfile = try await profileRepository.updateProfileCohort(id: activeProfile.id, cohort: cohort)
        return updatedProfile
    }

    func openDetail(item: StorefrontItem) {
        detailViewModel.present(item: item)
        push(.detail(item))
    }

    func replaceDetail(item: StorefrontItem) {
        detailViewModel.present(item: item)
        replaceTopRoute(with: .detail(item))
    }

    func play(item: StorefrontItem) {
        activePlaybackContent = item.quickplayPlaybackContent()
    }

    func play(detail: ContentDetail) {
        activePlaybackContent = detail.quickplayPlaybackContent(fallback: nil)
    }

    func play(detail: ContentDetail, fallback item: StorefrontItem?) {
        playerEpisodes = detailViewModel.episodes
        playerSeasons = detailViewModel.seasons

        // If the engine is already playing a different episode (e.g. user switched
        // episodes in the inline player), use that episode instead of the original
        // detail so the fullscreen player doesn't reload from the beginning.
        if let loadedId = playerEngine.loadedContentId,
           loadedId != detail.id,
           let playingEpisode = playerEpisodes.first(where: { $0.id == loadedId }) {
            activePlaybackContent = playingEpisode.quickplayPlaybackContent()
        } else if detail.supportsEpisodes, let firstEpisode = playerEpisodes.first {
            // Series/season types must auth with an episode ID, not the series ID.
            activePlaybackContent = firstEpisode.quickplayPlaybackContent()
        } else {
            activePlaybackContent = detail.quickplayPlaybackContent(fallback: item)
        }
    }

    func closePlayer() {
        let hasDetailBehindPlayer = navigationPath.contains {
            if case .detail = $0 { return true }
            return false
        }
        if !hasDetailBehindPlayer {
            playerEngine.pause()
        }
        activePlaybackContent = nil
        playerEpisodes = []
        playerSeasons = []
    }

    func openSectionBrowse(section: StorefrontSection, cohort: QuickplayCohort) {
        storefrontSectionBrowseViewModel.present(section: section, cohort: cohort)
        push(.sectionBrowse(section, cohort))
    }

    func openCollectionBrowse(item: StorefrontItem, cohort: QuickplayCohort) {
        storefrontSectionBrowseViewModel.present(collection: item, cohort: cohort)
        push(.collectionBrowse(item, cohort))
    }

    func backFromDetail() {
        popRoute()
    }

    private func openPlayerBackedContent(_ item: StorefrontItem) {
        activePlaybackContent = item.quickplayPlaybackContent()
    }

    func handleNavigationPathChange(from oldPath: [Route], to newPath: [Route]) {
        guard newPath.count < oldPath.count else { return }

        let removedRoutes = oldPath.suffix(oldPath.count - newPath.count)
        if removedRoutes.contains(where: {
            if case .otp = $0 { return true }
            return false
        }) {
            authViewModel.resetOTPState()
        }

        if let lastRoute = newPath.last, case let .detail(item) = lastRoute {
            detailViewModel.present(item: item)
        }
    }

    func popRoute() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    private func push(_ route: Route) {
        guard navigationPath.last != route else { return }
        navigationPath.append(route)
    }

    private func replaceTopRoute(with route: Route) {
        guard !navigationPath.isEmpty else {
            push(route)
            return
        }
        navigationPath[navigationPath.count - 1] = route
    }

}

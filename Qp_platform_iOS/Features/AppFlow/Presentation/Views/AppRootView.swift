import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel = AppFlowViewModel()

    var body: some View {
        ZStack {
            NavigationStack(path: $viewModel.navigationPath) {
                rootScene
                    .navigationDestination(for: AppFlowViewModel.Route.self) { route in
                        destination(for: route)
                    }
            }
            .overlay(alignment: .bottom) {
                if let cohortOverrideToast = viewModel.cohortOverrideToast {
                    CohortResultToast(message: cohortOverrideToast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 118)
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: viewModel.cohortOverrideToast)

            if let content = viewModel.activePlaybackContent {
                QuickplayPlayerScreen(
                    content: content,
                    engine: viewModel.playerEngine,
                    episodes: viewModel.playerEpisodes,
                    seasons: viewModel.playerSeasons,
                    onPlayEpisode: { item in viewModel.play(item: item) },
                    onDismiss: viewModel.closePlayer
                )
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.46, dampingFraction: 0.9), value: viewModel.activePlaybackContent != nil)
        .preferredColorScheme(.dark)
        .task {
            await viewModel.start()
        }
        .onChange(of: viewModel.navigationPath) { oldPath, newPath in
            viewModel.handleNavigationPathChange(from: oldPath, to: newPath)
        }
    }

    private var splashView: some View {
        VStack {
            Spacer()
            LogoGlowView(size: 92, glowScale: 1.5)
            Spacer()
        }
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private var rootScene: some View {
        switch viewModel.rootScreen {
        case .splash:
            surface(style: .auth) { splashView }
        case .login:
            surface(style: .auth) {
                LoginView(viewModel: viewModel.authViewModel, onBack: {}, onContinue: {
                    Task { await viewModel.submitPhoneNumber() }
                })
            }
        case .profileSelection:
            surface(style: .profile) {
                ProfileSelectionView(
                    viewModel: viewModel.profileSelectionViewModel,
                    onSelect: { profile in
                        viewModel.selectProfile(profile)
                    },
                    onAddProfile: {
                        viewModel.openProfileEditor(nil)
                    },
                    onEditProfiles: {
                        viewModel.openProfileEditor(viewModel.profileSelectionViewModel.defaultEditableProfile)
                    }
                )
            }
        case .main:
            mainScene
        }
    }

    @ViewBuilder
    private var mainScene: some View {
        switch viewModel.mainTab {
        case .storefront:
            surface(style: .storefront) {
                StorefrontView(
                    viewModel: viewModel.storefrontViewModel,
                    bottomSelection: .home,
                    profileName: viewModel.activeProfile?.name ?? "Default",
                    profileImageName: ProfileArtworkResolver.imageName(for: viewModel.activeProfile),
                    onSelectItem: { item in
                        viewModel.openContent(item: item)
                    },
                    onOpenHome: {
                        viewModel.openStorefront()
                    },
                    onOpenSearch: {
                        viewModel.openSearch()
                    },
                    onOpenShorts: {
                        viewModel.openShorts()
                    },
                    onOpenHot: {
                        viewModel.openHotTab()
                    },
                    onProfileTap: {
                        viewModel.openProfileHome()
                    },
                    onViewAllSection: { section in
                        viewModel.openSectionBrowse(section: section, cohort: viewModel.storefrontViewModel.activeCohort)
                    },
                    hidesFirstStorefrontTabInDock: true,
                    onOpenStorefrontTab: { tab in
                        viewModel.openStorefrontTab(tab)
                    }
                )
            }
        case .hot:
            surface(style: .storefront) {
                StorefrontView(
                    viewModel: viewModel.hotStorefrontViewModel,
                    bottomSelection: .hot,
                    profileName: viewModel.activeProfile?.name ?? "Default",
                    profileImageName: ProfileArtworkResolver.imageName(for: viewModel.activeProfile),
                    onSelectItem: { item in
                        viewModel.openContent(item: item)
                    },
                    onOpenHome: {
                        viewModel.openStorefront()
                    },
                    onOpenSearch: {
                        viewModel.openSearch()
                    },
                    onOpenShorts: {
                        viewModel.openShorts()
                    },
                    onOpenHot: {
                        viewModel.openHotTab()
                    },
                    onProfileTap: {
                        viewModel.openProfileHome()
                    },
                    onViewAllSection: { section in
                        viewModel.openSectionBrowse(section: section, cohort: viewModel.hotStorefrontViewModel.activeCohort)
                    }
                )
            }
        case .search:
            surface(style: .search) {
                SearchView(
                    viewModel: viewModel.searchViewModel,
                    profileName: viewModel.activeProfile?.name ?? "Default",
                    prefersVoiceAISearch: viewModel.prefersVoiceAISearch,
                    onBack: {
                        viewModel.openStorefront()
                    },
                    onOpenAISearch: {
                        viewModel.openAISearch()
                    },
                    onSelectItem: { item in
                        viewModel.openContent(item: item)
                    }
                )
            }
        case .shorts:
            ShortsTabView(
                viewModel: viewModel.shortsViewModel,
                profileName: viewModel.activeProfile?.name ?? "Default",
                profileImageName: ProfileArtworkResolver.imageName(for: viewModel.activeProfile),
                onOpenHome: {
                    viewModel.openStorefront()
                },
                onOpenSearch: {
                    viewModel.openSearch()
                },
                onOpenHot: {
                    viewModel.openHotTab()
                },
                onProfileTap: {
                    viewModel.openProfileHome()
                }
            )
        }
    }

    @ViewBuilder
    private func destination(for route: AppFlowViewModel.Route) -> some View {
        switch route {
        case .otp:
            surface(style: .auth) {
                OTPView(viewModel: viewModel.authViewModel, onBack: {
                    viewModel.backToLogin()
                }, onVerify: {
                    await viewModel.verifyOTP()
                }, onContinueAfterSuccess: {
                    await viewModel.finishVerifiedSignIn()
                })
            }
            .routeNavigationChrome(showsNavigationBar: false)
        case .search:
            surface(style: .search) {
                SearchView(
                    viewModel: viewModel.searchViewModel,
                    profileName: viewModel.activeProfile?.name ?? "Default",
                    prefersVoiceAISearch: viewModel.prefersVoiceAISearch,
                    onBack: {
                        viewModel.popRoute()
                    },
                    onOpenAISearch: {
                        viewModel.openAISearch()
                    },
                    onSelectItem: { item in
                        viewModel.openContent(item: item)
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
            .routeNavigationOverlay(title: AppStrings.Search.placeholder, onBack: viewModel.popRoute)
        case .aiSearch:
            surface(style: .search) {
                AISearchVoiceRouteView(
                    viewModel: viewModel.searchViewModel,
                    onBack: {
                        viewModel.popRoute()
                    },
                    onSubmit: { displayText, apiQuery in
                        viewModel.completeAISearch(displayText: displayText, apiQuery: apiQuery)
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
        case .profileEditor:
            surface(style: .profile) {
                ProfileEditorView(
                    viewModel: viewModel.profileEditorViewModel,
                    onBack: {
                        viewModel.popRoute()
                    },
                    onChooseAvatar: {
                        viewModel.openAvatarPicker()
                    },
                    onSave: {
                        viewModel.saveProfile()
                    },
                    onDelete: {
                        viewModel.deleteProfile()
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
        case .avatarPicker:
            surface(style: .profile) {
                AvatarPickerView(
                    viewModel: viewModel.profileEditorViewModel,
                    onBack: {
                        viewModel.closeAvatarPicker()
                    },
                    onContinue: {
                        viewModel.continueFromAvatarPicker()
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
        case .profileHome:
            surface(style: .storefront) {
                ProfileHubView(
                    viewModel: viewModel.profileHubViewModel,
                    profiles: viewModel.profileSelectionViewModel.selectionProfiles,
                    onBack: {
                        viewModel.backFromProfileHome()
                    },
                    onOpenSettings: {
                        viewModel.openSettings()
                    },
                    onSwitchProfile: {
                        viewModel.openProfileSelection()
                    },
                    onAddProfile: {
                        viewModel.openProfileEditor(nil)
                    },
                    onEditProfiles: {
                        viewModel.openProfileEditor(viewModel.activeProfile ?? viewModel.profileSelectionViewModel.defaultEditableProfile)
                    },
                    onSelectProfile: { profile in
                        viewModel.switchActiveProfileAndOpenStorefront(profile)
                    },
                    onSelectItem: { item in
                        viewModel.openContent(item: item)
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
            .routeNavigationOverlay(title: viewModel.activeProfile?.name ?? "Profile", onBack: viewModel.backFromProfileHome) {
                HStack(spacing: 4) {
                    RouteNavigationIconButton(icon: AppIcons.Action.download, action: {})
                    RouteNavigationIconButton(icon: AppIcons.Action.gear, action: viewModel.openSettings)
                }
            }
        case .settings:
            surface(style: .storefront) {
                SettingsView(
                    activeProfile: viewModel.activeProfile,
                    profiles: viewModel.profileSelectionViewModel.selectionProfiles,
                    isVoiceAISearchEnabled: viewModel.prefersVoiceAISearch,
                    onBack: {
                        viewModel.backFromSettings()
                    },
                    onSignOut: {
                        viewModel.signOut()
                    },
                    onSelectProfile: { profile in
                        viewModel.switchActiveProfileAndOpenStorefront(profile)
                    },
                    onVoiceAISearchChange: { isEnabled in
                        viewModel.setPrefersVoiceAISearch(isEnabled)
                    },
                    onAddProfile: {
                        viewModel.openProfileEditor(nil)
                    },
                    onEditProfiles: {
                        viewModel.openProfileEditor(viewModel.profileSelectionViewModel.defaultEditableProfile)
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
        case .storefrontTab(let tab):
            surface(style: .storefront) {
                StorefrontTabRouteView(
                    tab: tab,
                    activeProfile: viewModel.activeProfile,
                    onSelectItem: { item in
                        viewModel.openContent(item: item)
                    },
                    onOpenHome: {
                        viewModel.openStorefront()
                    },
                    onOpenSearch: {
                        viewModel.openSearch()
                    },
                    onOpenShorts: {
                        viewModel.openShorts()
                    },
                    onOpenHot: {
                        viewModel.openHotTab()
                    },
                    onProfileTap: {
                        viewModel.openProfileHome()
                    },
                    onViewAllSection: { section in
                        viewModel.openSectionBrowse(section: section, cohort: viewModel.storefrontViewModel.activeCohort)
                    },
                    onOpenStorefrontTab: { nextTab in
                        viewModel.openStorefrontTab(nextTab)
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
            .routeNavigationOverlay(title: tab.title, onBack: viewModel.popRoute)
        case .detail:
            surface(style: .storefront) {
                ContentDetailView(
                    viewModel: viewModel.detailViewModel,
                    engine: viewModel.playerEngine,
                    onBack: {
                        viewModel.backFromDetail()
                    },
                    onPlay: { detail, item in
                        viewModel.play(detail: detail, fallback: item)
                    },
                    onPlayEpisode: { item in
                        viewModel.play(item: item)
                    },
                    onSelectRecommendation: { item in
                        viewModel.openContent(item: item)
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
            .routeNavigationOverlay(onBack: viewModel.backFromDetail)
        case .sectionBrowse, .collectionBrowse:
            surface(style: .storefront) {
                StorefrontSectionBrowseView(
                    viewModel: viewModel.storefrontSectionBrowseViewModel,
                    onBack: {
                        viewModel.popRoute()
                    },
                    onSelectItem: { item in
                        viewModel.openContent(item: item)
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
        }
    }

    private func surface<Content: View>(style: AppBackgroundStyle, @ViewBuilder content: () -> Content) -> some View {
        ZStack {
            AppBackgroundView(style: style)
            content()
        }
    }
}

private struct StorefrontTabRouteView: View {
    let tab: StorefrontTab
    let activeProfile: Profile?
    let onSelectItem: (StorefrontItem) -> Void
    let onOpenHome: () -> Void
    let onOpenSearch: () -> Void
    let onOpenShorts: () -> Void
    let onOpenHot: () -> Void
    let onProfileTap: () -> Void
    let onViewAllSection: (StorefrontSection) -> Void
    let onOpenStorefrontTab: (StorefrontTab) -> Void
    @StateObject private var tabViewModel: StorefrontViewModel
    @State private var loadedProfileID: UUID?

    init(
        tab: StorefrontTab,
        activeProfile: Profile?,
        onSelectItem: @escaping (StorefrontItem) -> Void,
        onOpenHome: @escaping () -> Void,
        onOpenSearch: @escaping () -> Void,
        onOpenShorts: @escaping () -> Void,
        onOpenHot: @escaping () -> Void,
        onProfileTap: @escaping () -> Void,
        onViewAllSection: @escaping (StorefrontSection) -> Void,
        onOpenStorefrontTab: @escaping (StorefrontTab) -> Void
    ) {
        self.tab = tab
        self.activeProfile = activeProfile
        self.onSelectItem = onSelectItem
        self.onOpenHome = onOpenHome
        self.onOpenSearch = onOpenSearch
        self.onOpenShorts = onOpenShorts
        self.onOpenHot = onOpenHot
        self.onProfileTap = onProfileTap
        self.onViewAllSection = onViewAllSection
        self.onOpenStorefrontTab = onOpenStorefrontTab
        let container = AppContainer.shared
        _tabViewModel = StateObject(
            wrappedValue: StorefrontViewModel(
                initialUseCase: GetInitialStorefrontUseCase(repository: container.storefrontRepository),
                pageUseCase: GetStorefrontPageUseCase(repository: container.storefrontRepository),
                preferredInitialTabTitle: tab.title
            )
        )
    }

    var body: some View {
        StorefrontView(
            viewModel: tabViewModel,
            bottomSelection: .home,
            profileName: activeProfile?.name ?? "Default",
            profileImageName: ProfileArtworkResolver.imageName(for: activeProfile),
            onSelectItem: onSelectItem,
            onOpenHome: onOpenHome,
            onOpenSearch: onOpenSearch,
            onOpenShorts: onOpenShorts,
            onOpenHot: onOpenHot,
            onProfileTap: onProfileTap,
            onViewAllSection: onViewAllSection,
            hidesFirstStorefrontTabInDock: true,
            showsStorefrontHeader: false,
            showsBottomChrome: false,
            loadsInitialOnAppear: false,
            scrollsToTopOnTabChange: false,
            onOpenStorefrontTab: onOpenStorefrontTab
        )
        .task(id: activeProfile?.id) {
            let profileID = activeProfile?.id
            guard loadedProfileID != profileID else { return }
            loadedProfileID = profileID
            tabViewModel.applyProfile(activeProfile, forceReset: true)
            await tabViewModel.reloadInitial(force: true)
        }
    }
}

#Preview {
    AppRootView()
}

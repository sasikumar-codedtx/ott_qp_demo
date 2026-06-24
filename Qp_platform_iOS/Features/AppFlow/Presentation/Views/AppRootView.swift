import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel = AppFlowViewModel()

    var body: some View {
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
        .preferredColorScheme(.dark)
        .task {
            await viewModel.start()
        }
        .onChange(of: viewModel.navigationPath) { oldPath, newPath in
            viewModel.handleNavigationPathChange(from: oldPath, to: newPath)
        }
        .fullScreenCover(item: $viewModel.activePlaybackContent) { content in
            QuickplayPlayerScreen(content: content, onDismiss: viewModel.closePlayer)
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
                    }
                )
            }
        case .hot:
            surface(style: .storefront) {
                StorefrontView(
                    viewModel: viewModel.hotStorefrontViewModel,
                    bottomSelection: .hot,
                    profileName: viewModel.activeProfile?.name ?? "Default",
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
                    onSubmit: { transcript in
                        viewModel.completeAISearch(transcript: transcript)
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
                        viewModel.switchActiveProfile(profile)
                    },
                    onVoiceAISearchChange: { isEnabled in
                        viewModel.setPrefersVoiceAISearch(isEnabled)
                    },
                    onEditProfiles: {
                        viewModel.openProfileEditor(viewModel.profileSelectionViewModel.defaultEditableProfile)
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
        case .detail:
            surface(style: .storefront) {
                ContentDetailView(
                    viewModel: viewModel.detailViewModel,
                    onBack: {
                        viewModel.backFromDetail()
                    },
                    onPlay: { detail, item in
                        viewModel.play(detail: detail, fallback: item)
                    },
                    onSelectRecommendation: { item in
                        viewModel.openContent(item: item)
                    }
                )
            }
            .routeNavigationChrome(showsNavigationBar: false)
            .routeNavigationOverlay(onBack: viewModel.backFromDetail) {
                HStack(spacing: 4) {
                    RouteNavigationIconButton(icon: AppIcons.Action.tv, action: {})
                    RouteNavigationIconButton(icon: AppIcons.Action.share, action: {})
                }
            }
        case .sectionBrowse:
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

#Preview {
    AppRootView()
}

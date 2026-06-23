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
                    onManageProfiles: {
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
            .routeNavigationChrome()
        case .search:
            surface(style: .search) {
                SearchView(
                    viewModel: viewModel.searchViewModel,
                    profileName: viewModel.activeProfile?.name ?? "Default",
                    prefersVoiceAISearch: viewModel.prefersVoiceAISearch,
                    onBack: {
                        viewModel.popRoute()
                    },
                    onSelectItem: { item in
                        viewModel.openContent(item: item)
                    }
                )
            }
            .routeNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationChromeButton(icon: AppIcons.Navigation.back, action: viewModel.popRoute)
                }
                ToolbarItem(placement: .principal) {
                    NavigationChromeTitle(title: AppStrings.Search.placeholder)
                }
            }
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
            .routeNavigationChrome()
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
            .routeNavigationChrome()
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
                        viewModel.switchActiveProfile(profile)
                    },
                    onSelectItem: { item in
                        viewModel.openContent(item: item)
                    }
                )
            }
            .routeNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationChromeButton(icon: AppIcons.Navigation.back, action: viewModel.backFromProfileHome)
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        ProfileAvatarView(
                            imageName: ProfileArtworkResolver.imageName(forName: viewModel.activeProfile?.name ?? "Default"),
                            fallbackGlyph: String((viewModel.activeProfile?.name ?? "P").prefix(1)).uppercased(),
                            size: 28
                        )
                        Text(viewModel.activeProfile?.name ?? "Profile")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationChromeButton(icon: AppIcons.Action.download, action: {})
                    NavigationChromeButton(icon: AppIcons.Action.gear, action: viewModel.openSettings)
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
            .routeNavigationChrome()
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
            .routeNavigationChrome()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationChromeButton(icon: AppIcons.Navigation.back, action: viewModel.backFromDetail)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationChromeButton(icon: AppIcons.Action.tv, action: {})
                    NavigationChromeButton(icon: AppIcons.Action.share, action: {})
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
            .routeNavigationChrome()
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

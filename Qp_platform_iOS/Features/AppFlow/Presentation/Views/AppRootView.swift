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
        .toolbar(.hidden, for: .navigationBar)
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
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
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
                        viewModel.openDetail(item: item)
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
                        viewModel.openDetail(item: item)
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
                    onSelectItem: { item in
                        viewModel.openDetail(item: item)
                    },
                    onOpenHome: {
                        viewModel.openStorefront()
                    },
                    onOpenShorts: {
                        viewModel.openShorts()
                    },
                    onOpenHot: {
                        viewModel.openHotTab()
                    },
                    onProfileTap: {
                        viewModel.openProfileHome()
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
                    onBack: {
                        viewModel.backFromProfileHome()
                    },
                    onOpenSettings: {
                        viewModel.openSettings()
                    },
                    onSwitchProfile: {
                        viewModel.openProfileSelection()
                    },
                    onSelectItem: { item in
                        viewModel.openDetail(item: item)
                    }
                )
            }
            .routeNavigationChrome()
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
                    onSelectRecommendation: { item in
                        viewModel.openDetail(item: item)
                    }
                )
            }
            .routeNavigationChrome()
        case .sectionBrowse:
            surface(style: .storefront) {
                StorefrontSectionBrowseView(
                    viewModel: viewModel.storefrontSectionBrowseViewModel,
                    onBack: {
                        viewModel.popRoute()
                    },
                    onSelectItem: { item in
                        viewModel.openDetail(item: item)
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

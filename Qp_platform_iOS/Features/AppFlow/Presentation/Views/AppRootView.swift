import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel = AppFlowViewModel()

    var body: some View {
        ZStack {
            AppBackgroundView(style: backgroundStyle)

            switch viewModel.screen {
            case .splash:
                splashView

            case .login:
                LoginView(viewModel: viewModel.authViewModel, onContinue: {
                    Task { await viewModel.submitPhoneNumber() }
                })

            case .otp:
                OTPView(viewModel: viewModel.authViewModel, onBack: {
                    viewModel.backToLogin()
                }, onVerify: {
                    Task { await viewModel.verifyOTP() }
                })

            case .profileSelection:
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

            case .profileEditor:
                ProfileEditorView(
                    viewModel: viewModel.profileEditorViewModel,
                    onBack: {
                        viewModel.screen = .profileSelection
                    },
                    onChooseAvatar: {
                        viewModel.openAvatarPicker()
                    },
                    onSave: {
                        viewModel.saveProfile()
                    }
                )

            case .avatarPicker:
                AvatarPickerView(
                    viewModel: viewModel.profileEditorViewModel,
                    onBack: {
                        viewModel.closeAvatarPicker()
                    }
                )

            case .storefront:
                StorefrontView(
                    viewModel: viewModel.storefrontViewModel,
                    profileName: viewModel.activeProfile?.name ?? "Randy Orton",
                    onSelectItem: { item in
                        viewModel.openDetail(item: item)
                    },
                    onOpenSearch: {
                        viewModel.openSearch()
                    },
                    onProfileTap: {
                        viewModel.openProfileHome()
                    }
                )

            case .profileHome:
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

            case .settings:
                SettingsView(
                    onBack: {
                        viewModel.backFromSettings()
                    },
                    onSignOut: {
                        viewModel.signOut()
                    }
                )

            case .search:
                SearchView(
                    viewModel: viewModel.searchViewModel,
                    profileName: viewModel.activeProfile?.name ?? "Randy Orton",
                    onSelectItem: { item in
                        viewModel.openDetail(item: item)
                    },
                    onOpenHome: {
                        viewModel.openStorefront()
                    },
                    onOpenHot: {
                        viewModel.openHotTab()
                    },
                    onProfileTap: {
                        viewModel.openProfileHome()
                    }
                )

            case .detail:
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
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.start()
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

    private var backgroundStyle: AppBackgroundStyle {
        switch viewModel.screen {
        case .profileSelection, .profileEditor, .avatarPicker:
            return .profile
        case .storefront, .detail, .profileHome, .settings:
            return .storefront
        case .search:
            return .search
        default:
            return .auth
        }
    }
}

#Preview {
    AppRootView()
}

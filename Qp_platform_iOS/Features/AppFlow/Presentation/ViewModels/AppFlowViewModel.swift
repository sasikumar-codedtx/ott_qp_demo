import Combine
import Foundation

@MainActor
final class AppFlowViewModel: ObservableObject {
    enum Screen {
        case splash
        case login
        case otp
        case profileSelection
        case profileEditor
        case avatarPicker
        case storefront
        case profileHome
        case settings
        case search
        case detail
    }

    @Published var screen: Screen = .splash
    @Published private(set) var activeProfile: Profile?

    let authViewModel: AuthViewModel
    let profileSelectionViewModel: ProfileSelectionViewModel
    let profileEditorViewModel: ProfileEditorViewModel
    let profileHubViewModel: ProfileHubViewModel
    let storefrontViewModel: StorefrontViewModel
    let searchViewModel: SearchViewModel
    let detailViewModel: ContentDetailViewModel

    private var detailReturnScreen: Screen = .storefront
    private var profileReturnScreen: Screen = .storefront
    private var hasStarted = false

    convenience init() {
        self.init(container: .shared)
    }

    init(container: AppContainer) {
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

        searchViewModel = SearchViewModel(
            useCase: SearchContentUseCase(repository: container.searchRepository)
        )

        detailViewModel = ContentDetailViewModel(
            detailUseCase: GetContentDetailUseCase(repository: container.contentDetailRepository),
            recommendationsUseCase: GetRecommendationsUseCase(repository: container.contentDetailRepository)
        )
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        try? await Task.sleep(for: .seconds(1.2))
        screen = .login
    }

    func submitPhoneNumber() async {
        if await authViewModel.requestOTP() {
            screen = .otp
        }
    }

    func verifyOTP() async {
        if await authViewModel.verifyOTP() {
            await profileSelectionViewModel.load()
            screen = .profileSelection
        }
    }

    func backToLogin() {
        authViewModel.resetOTPState()
        screen = .login
    }

    func selectProfile(_ profile: Profile) {
        activeProfile = profile
        screen = .storefront
    }

    func openProfileEditor(_ profile: Profile?) {
        Task {
            if let profile {
                await profileEditorViewModel.prepareForEdit(profile: profile)
            } else {
                await profileEditorViewModel.prepareForCreate()
            }
            await MainActor.run {
                screen = .profileEditor
            }
        }
    }

    func saveProfile() {
        Task {
            let saved = await profileEditorViewModel.save()
            guard saved != nil else { return }
            await profileSelectionViewModel.load()
            await MainActor.run {
                screen = .profileSelection
            }
        }
    }

    func openAvatarPicker() {
        screen = .avatarPicker
    }

    func closeAvatarPicker() {
        screen = .profileEditor
    }

    func openSearch() {
        searchViewModel.present(popularItems: storefrontViewModel.searchSeedItems)
        screen = .search
    }

    func openProfileHome() {
        let profile = activeProfile ?? profileSelectionViewModel.defaultEditableProfile
        profileHubViewModel.present(profile: profile, seedItems: storefrontViewModel.searchSeedItems)
        profileReturnScreen = screen == .search ? .search : .storefront
        screen = .profileHome
    }

    func backFromProfileHome() {
        screen = profileReturnScreen
    }

    func openSettings() {
        screen = .settings
    }

    func backFromSettings() {
        screen = .profileHome
    }

    func openProfileSelection() {
        Task {
            await profileSelectionViewModel.load()
            await MainActor.run {
                screen = .profileSelection
            }
        }
    }

    func signOut() {
        authViewModel.resetOTPState()
        activeProfile = nil
        screen = .login
    }

    func openStorefront() {
        screen = .storefront
    }

    func openHotTab() {
        Task {
            await storefrontViewModel.selectHotTabIfNeeded()
            await MainActor.run {
                screen = .storefront
            }
        }
    }

    func openDetail(item: StorefrontItem) {
        switch screen {
        case .search:
            detailReturnScreen = .search
        case .profileHome:
            detailReturnScreen = .profileHome
        default:
            detailReturnScreen = .storefront
        }
        detailViewModel.present(item: item)
        screen = .detail
    }

    func backFromDetail() {
        screen = detailReturnScreen
    }
}

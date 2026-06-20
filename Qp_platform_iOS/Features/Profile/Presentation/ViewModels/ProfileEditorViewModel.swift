import Combine
import Foundation

enum ProfileEditorMode {
    case editExisting
    case createNew
}

@MainActor
final class ProfileEditorViewModel: ObservableObject {
    @Published var draft = ProfileDraft()
    @Published private(set) var avatarOptions: [AvatarOption] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var mode: ProfileEditorMode = .createNew

    private let repository: ProfileRepository
    private let saveProfileUseCase: SaveProfileUseCase

    init(repository: ProfileRepository, saveProfileUseCase: SaveProfileUseCase) {
        self.repository = repository
        self.saveProfileUseCase = saveProfileUseCase
    }

    func prepareForEdit(profile: Profile) async {
        mode = .editExisting
        draft = ProfileDraft(profile: profile)
        await loadAvatarOptionsIfNeeded()
    }

    func prepareForCreate() async {
        mode = .createNew
        draft = ProfileDraft()
        draft.imageName = "profile-karan-main"
        await loadAvatarOptionsIfNeeded()
    }

    func save() async -> Profile? {
        isLoading = true
        errorMessage = nil

        do {
            let profile = try await saveProfileUseCase.execute(draft: draft)
            isLoading = false
            return profile
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }

    func selectAvatar(_ option: AvatarOption) {
        draft.imageName = option.imageName
    }

    private func loadAvatarOptionsIfNeeded() async {
        guard avatarOptions.isEmpty else { return }
        do {
            avatarOptions = try await repository.fetchAvatarOptions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

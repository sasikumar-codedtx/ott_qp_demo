import Combine
import Foundation

@MainActor
final class ProfileSelectionViewModel: ObservableObject {
    @Published private(set) var profiles: [Profile] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let getProfilesUseCase: GetProfilesUseCase

    init(getProfilesUseCase: GetProfilesUseCase) {
        self.getProfilesUseCase = getProfilesUseCase
    }

    var selectionProfiles: [Profile] {
        profiles.filter(\.showOnSelection)
    }

    var canAddProfile: Bool {
        selectionProfiles.count < 5
    }

    var defaultEditableProfile: Profile? {
        profiles.first(where: { !$0.isKidsProfile }) ?? profiles.first
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            profiles = try await getProfilesUseCase.execute()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

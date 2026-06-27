import Combine
import Foundation

enum ProfileEditorMode {
    case editExisting
    case createNew
}

enum ProfileEditorStep: Int, CaseIterable {
    case details
    case cohortSelection
}

@MainActor
final class ProfileEditorViewModel: ObservableObject {
    @Published var draft = ProfileDraft()
    @Published private(set) var avatarOptions: [AvatarOption] = []
    @Published private(set) var profiles: [Profile] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var mode: ProfileEditorMode = .createNew
    @Published private(set) var step: ProfileEditorStep = .details
    @Published var isGenderPickerPresented = false
    @Published var isDatePickerPresented = false
    @Published var selectedStorefrontPolicy: StorefrontPolicy = .entertainment

    private let repository: ProfileRepository
    private let saveProfileUseCase: SaveProfileUseCase

    init(repository: ProfileRepository, saveProfileUseCase: SaveProfileUseCase) {
        self.repository = repository
        self.saveProfileUseCase = saveProfileUseCase
    }

    var showsCohortStep: Bool {
        mode == .createNew
    }

    var displayAvatarOptions: [AvatarOption] {
        avatarOptions
    }

    var canDeleteProfile: Bool {
        mode == .editExisting && draft.sourceID != nil
    }

    var callToActionTitle: String {
        if mode == .editExisting {
            return AppStrings.Profile.saveProfile
        }

        switch step {
        case .details:
            return AppStrings.Profile.continueProfile
        case .cohortSelection:
            return AppStrings.Profile.saveProfile
        }
    }

    var title: String {
        switch (mode, step) {
        case (.createNew, .details):
            return AppStrings.Profile.createProfile
        case (.editExisting, _):
            return AppStrings.Profile.editProfile
        case (.createNew, .cohortSelection):
            return AppStrings.Profile.chooseCohort
        }
    }

    var isSaveStep: Bool {
        mode == .editExisting || step == .cohortSelection
    }

    func prepareForEdit(profile: Profile) async {
        mode = .editExisting
        step = .details
        draft = ProfileDraft(profile: profile)
        selectedStorefrontPolicy = await DemoSessionStore.shared.storefrontPolicy(for: profile.id)
        await loadProfiles()
        await loadAvatarOptionsIfNeeded()
        applyFallbackAvatarIfNeeded()
    }

    func prepareForCreate() async {
        mode = .createNew
        step = .details
        draft = ProfileDraft()
        selectedStorefrontPolicy = .entertainment
        await loadProfiles()
        await loadAvatarOptionsIfNeeded()
        applyFallbackAvatarIfNeeded()
    }

    func save() async -> Profile? {
        guard validateBeforeSave() else { return nil }

        isLoading = true
        errorMessage = nil

        do {
            let profile = try await saveProfileUseCase.execute(draft: draft)
            await DemoSessionStore.shared.setStorefrontPolicyOverride(selectedStorefrontPolicy, for: profile.id)
            isLoading = false
            return profile
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }

    func deleteCurrentProfile() async -> Bool {
        guard let sourceID = draft.sourceID else { return false }

        isLoading = true
        errorMessage = nil

        do {
            try await repository.deleteProfile(id: sourceID)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func advanceStepIfPossible() -> Bool {
        guard mode == .createNew else { return true }
        guard step == .details else { return true }
        guard validateDetailsStep() else { return false }
        step = .cohortSelection
        return true
    }

    func handleBack() -> Bool {
        if mode == .createNew, step == .cohortSelection {
            step = .details
            errorMessage = nil
            return true
        }

        return false
    }

    func selectAvatar(_ option: AvatarOption) {
        draft.imageName = option.imageName
        errorMessage = nil
    }

    func selectProfileForEditing(_ profile: Profile) {
        mode = .editExisting
        step = .details
        draft = ProfileDraft(profile: profile)
        Task {
            selectedStorefrontPolicy = await DemoSessionStore.shared.storefrontPolicy(for: profile.id)
        }
        isGenderPickerPresented = false
        isDatePickerPresented = false
        errorMessage = nil
        applyFallbackAvatarIfNeeded()
    }

    func selectGender(_ gender: ProfileGender) {
        draft.gender = gender
        isGenderPickerPresented = false
        errorMessage = nil
    }

    func toggleLanguage(_ language: ProfileLanguage) {
        if draft.preferredLanguages.contains(language) {
            draft.preferredLanguages.removeAll { $0 == language }
        } else {
            draft.preferredLanguages.append(language)
        }

        if draft.preferredLanguages.isEmpty {
            draft.preferredLanguages = [.english]
        }
        errorMessage = nil
    }

    func selectPreference(_ preference: ProfilePreference) {
        draft.preference = preference
        draft.cohort = preference.quickplayCohort
        draft.isKidsProfile = false
        selectedStorefrontPolicy = storefrontPolicy(for: preference.quickplayCohort)
        errorMessage = nil
    }

    func applyCohortQuestionnaireResult(_ result: CohortQuestionnaireResult) {
        draft.cohort = result.primaryCategory
        draft.preference = result.preference
        draft.isKidsProfile = false
        draft.preferredLanguages = preferredLanguages(for: result.preference)
        selectedStorefrontPolicy = storefrontPolicy(for: result.primaryCategory)
        errorMessage = nil
    }

    func selectStorefrontPolicy(_ policy: StorefrontPolicy) {
        selectedStorefrontPolicy = policy
        switch policy {
        case .sports, .sportsEntertainment:
            draft.preference = .sports
            draft.cohort = .sports
            draft.isKidsProfile = false
        case .reality, .realityEntertainment, .realitySports:
            draft.preference = .realityShows
            draft.cohort = .realityShows
            draft.isKidsProfile = false
        case .entertainment:
            draft.preference = .entertainment
            draft.cohort = .entertainment
            draft.isKidsProfile = false
        }
        errorMessage = nil
    }

    func formattedDateOfBirth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: draft.dateOfBirth)
    }

    func preferredLanguages(for preference: ProfilePreference) -> [ProfileLanguage] {
        switch preference {
        case .entertainment:
            return [.hindi, .english, .telugu]
        case .sports:
            return [.english, .hindi, .tamil]
        case .realityShows:
            return [.hindi, .bengali, .english]
        }
    }

    private func validateDetailsStep() -> Bool {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Enter a profile name to continue."
            return false
        }

        guard draft.gender != nil else {
            errorMessage = "Select a gender to continue."
            return false
        }

        guard !draft.preferredLanguages.isEmpty else {
            errorMessage = "Pick at least one preferred language."
            return false
        }

        errorMessage = nil
        return true
    }

    private func validateBeforeSave() -> Bool {
        guard validateDetailsStep() else { return false }

        errorMessage = nil
        return true
    }

    private func loadAvatarOptionsIfNeeded() async {
        guard avatarOptions.isEmpty else { return }
        do {
            avatarOptions = try await repository.fetchAvatarOptions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProfiles() async {
        do {
            profiles = try await repository.fetchProfiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyFallbackAvatarIfNeeded() {
        guard draft.imageName == nil else { return }
        draft.imageName = avatarOptions.first?.imageName
    }

    private func storefrontPolicy(for cohort: QuickplayCohort) -> StorefrontPolicy {
        switch cohort {
        case .sports:
            return .sports
        case .realityShows:
            return .reality
        case .kids, .entertainment:
            return .entertainment
        }
    }
}

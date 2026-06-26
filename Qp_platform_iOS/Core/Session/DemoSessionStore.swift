import Foundation

actor DemoSessionStore {
    static let shared = DemoSessionStore()

    private enum StorageKey {
        static let activeCohort = "sony.quickplay.demo.active-cohort"
        static let activePreference = "sony.quickplay.demo.active-preference"
        static let activeProfileID = "sony.quickplay.demo.active-profile-id"
        static let preferenceHistoryByProfile = "sony.quickplay.demo.preference-history-by-profile"
        static let cohortTapCountsByProfile = "sony.quickplay.demo.cohort-tap-counts-by-profile"
        static let prefersVoiceAISearch = "sony.quickplay.demo.prefers-voice-ai"
        static let continueWatchingByProfile = "sony.quickplay.demo.continue-watching-by-profile"
        static let favoritesByProfile = "sony.quickplay.demo.favorites-by-profile"
        static let hasCompletedLogin = "sony.quickplay.demo.has-completed-login"
    }

    private let historyThreshold = 7
    private let maxHistoryCount = 24

    private var activeCohort: QuickplayCohort
    private var activePreference: ProfilePreference
    private var activeProfileID: String?
    private var preferenceHistoryByProfile: [String: [String]]
    private var cohortTapCountsByProfile: [String: [String: Int]]
    private var prefersVoiceAISearch: Bool
    private var continueWatchingByProfile: [String: [StorefrontItem]]
    private var favoritesByProfile: [String: [StorefrontItem]]

    init() {
        if
            let rawCohort = UserDefaults.standard.string(forKey: StorageKey.activeCohort),
            let storedCohort = QuickplayCohort(rawValue: rawCohort)
        {
            activeCohort = storedCohort
        } else {
            activeCohort = .entertainment
        }

        if
            let rawPreference = UserDefaults.standard.string(forKey: StorageKey.activePreference),
            let storedPreference = ProfilePreference(rawValue: rawPreference)
        {
            activePreference = storedPreference
        } else {
            activePreference = .entertainment
        }

        activeProfileID = UserDefaults.standard.string(forKey: StorageKey.activeProfileID)
        preferenceHistoryByProfile = UserDefaults.standard.dictionary(forKey: StorageKey.preferenceHistoryByProfile) as? [String: [String]] ?? [:]
        cohortTapCountsByProfile = UserDefaults.standard.dictionary(forKey: StorageKey.cohortTapCountsByProfile) as? [String: [String: Int]] ?? [:]
        if let data = UserDefaults.standard.data(forKey: StorageKey.continueWatchingByProfile),
           let stored = try? JSONDecoder().decode([String: [StorefrontItem]].self, from: data) {
            continueWatchingByProfile = stored
        } else {
            continueWatchingByProfile = [:]
        }
        if let data = UserDefaults.standard.data(forKey: StorageKey.favoritesByProfile),
           let stored = try? JSONDecoder().decode([String: [StorefrontItem]].self, from: data) {
            favoritesByProfile = stored
        } else {
            favoritesByProfile = [:]
        }

        if UserDefaults.standard.object(forKey: StorageKey.prefersVoiceAISearch) != nil {
            prefersVoiceAISearch = UserDefaults.standard.bool(forKey: StorageKey.prefersVoiceAISearch)
        } else {
            prefersVoiceAISearch = true
        }
    }

    func setActiveProfileContext(profileID: UUID?, cohort: QuickplayCohort, preference: ProfilePreference) {
        activeProfileID = profileID?.uuidString
        activeCohort = cohort
        activePreference = preference
        UserDefaults.standard.set(activeProfileID, forKey: StorageKey.activeProfileID)
        UserDefaults.standard.set(cohort.rawValue, forKey: StorageKey.activeCohort)
        UserDefaults.standard.set(preference.rawValue, forKey: StorageKey.activePreference)
    }

    func resetPreferenceHistory(for profileID: UUID?) {
        guard let profileID else { return }
        preferenceHistoryByProfile[profileID.uuidString] = []
        cohortTapCountsByProfile[profileID.uuidString] = [:]
        UserDefaults.standard.set(preferenceHistoryByProfile, forKey: StorageKey.preferenceHistoryByProfile)
        UserDefaults.standard.set(cohortTapCountsByProfile, forKey: StorageKey.cohortTapCountsByProfile)
    }

    func clearActiveProfileContext() {
        activeProfileID = nil
        activeCohort = .entertainment
        activePreference = .entertainment
        UserDefaults.standard.set(false, forKey: StorageKey.hasCompletedLogin)
        UserDefaults.standard.removeObject(forKey: StorageKey.activeProfileID)
        UserDefaults.standard.set(activeCohort.rawValue, forKey: StorageKey.activeCohort)
        UserDefaults.standard.set(activePreference.rawValue, forKey: StorageKey.activePreference)
    }

    func setHasCompletedLogin(_ hasCompletedLogin: Bool) {
        UserDefaults.standard.set(hasCompletedLogin, forKey: StorageKey.hasCompletedLogin)
    }

    func hasCompletedLogin() -> Bool {
        UserDefaults.standard.bool(forKey: StorageKey.hasCompletedLogin)
    }

    func setActiveCohort(_ cohort: QuickplayCohort) {
        activeCohort = cohort
        UserDefaults.standard.set(cohort.rawValue, forKey: StorageKey.activeCohort)
    }

    func setActivePreference(_ preference: ProfilePreference) {
        activePreference = preference
        UserDefaults.standard.set(preference.rawValue, forKey: StorageKey.activePreference)
    }

    func recordContentSelection(_ item: StorefrontItem) -> QuickplayCohort? {
        let previousCohort = activeCohort
        let key = historyKey
        let tappedCohort = cohortSignal(from: item)
        var counts = cohortTapCountsByProfile[key] ?? [:]
        counts[tappedCohort.rawValue, default: 0] += 1
        cohortTapCountsByProfile[key] = counts
        UserDefaults.standard.set(cohortTapCountsByProfile, forKey: StorageKey.cohortTapCountsByProfile)

        var continueItems = continueWatchingByProfile[key] ?? []
        let progressValue = item.progress ?? 0.32
        let storedItem = item.withProgress(progressValue)
        continueItems.removeAll { $0.id == storedItem.id }
        continueItems.insert(storedItem, at: 0)
        if continueItems.count > maxHistoryCount {
            continueItems.removeLast(continueItems.count - maxHistoryCount)
        }
        continueWatchingByProfile[key] = continueItems
        persistContinueWatching()

        guard let updatedCohort = firstCohortAtThreshold(in: counts) else { return nil }

        cohortTapCountsByProfile[key] = [:]
        UserDefaults.standard.set(cohortTapCountsByProfile, forKey: StorageKey.cohortTapCountsByProfile)

        guard updatedCohort != previousCohort else { return nil }
        return updatedCohort
    }

    func continueWatchingItems(limit: Int = 20) -> [StorefrontItem] {
        Array((continueWatchingByProfile[historyKey] ?? []).prefix(limit))
    }

    func favoriteItems(limit: Int = 20) -> [StorefrontItem] {
        Array((favoritesByProfile[historyKey] ?? []).prefix(limit))
    }

    func favoriteIDs() -> Set<String> {
        Set((favoritesByProfile[historyKey] ?? []).map(\.id))
    }

    func toggleFavorite(_ item: StorefrontItem) -> Bool {
        var items = favoritesByProfile[historyKey] ?? []
        if let existingIndex = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: existingIndex)
            favoritesByProfile[historyKey] = items
            persistFavorites()
            return false
        }

        items.insert(item, at: 0)
        if items.count > maxHistoryCount {
            items.removeLast(items.count - maxHistoryCount)
        }
        favoritesByProfile[historyKey] = items
        persistFavorites()
        return true
    }

    func currentCohort() -> QuickplayCohort {
        activeCohort
    }

    func currentSelectedCohort() -> QuickplayCohort {
        activeCohort
    }

    func currentSelectedPreference() -> ProfilePreference {
        activePreference
    }

    func currentDominantPreference() -> ProfilePreference? {
        nil
    }

    func setPrefersVoiceAISearch(_ prefersVoice: Bool) {
        prefersVoiceAISearch = prefersVoice
        UserDefaults.standard.set(prefersVoice, forKey: StorageKey.prefersVoiceAISearch)
    }

    func currentPrefersVoiceAISearch() -> Bool {
        prefersVoiceAISearch
    }

    private var historyKey: String {
        activeProfileID ?? "guest"
    }

    private func cohortSignal(from item: StorefrontItem) -> QuickplayCohort {
        let value = item.customSearchCategory?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch value {
        case "sports":
            return .sports
        case "shows":
            return .realityShows
        default:
            return .entertainment
        }
    }

    private func firstCohortAtThreshold(in counts: [String: Int]) -> QuickplayCohort? {
        let candidates: [QuickplayCohort] = [.sports, .realityShows, .entertainment]
        return candidates.first { cohort in
            (counts[cohort.rawValue] ?? 0) >= historyThreshold
        }
    }

    private func persistContinueWatching() {
        guard let data = try? JSONEncoder().encode(continueWatchingByProfile) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.continueWatchingByProfile)
    }

    private func persistFavorites() {
        guard let data = try? JSONEncoder().encode(favoritesByProfile) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.favoritesByProfile)
    }
}

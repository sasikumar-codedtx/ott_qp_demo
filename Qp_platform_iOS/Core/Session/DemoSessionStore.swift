import Foundation

actor DemoSessionStore {
    static let shared = DemoSessionStore()

    private enum StorageKey {
        static let activeCohort = "sony.quickplay.demo.active-cohort"
        static let activePreference = "sony.quickplay.demo.active-preference"
        static let activeProfileID = "sony.quickplay.demo.active-profile-id"
        static let preferenceHistoryByProfile = "sony.quickplay.demo.preference-history-by-profile"
        static let prefersVoiceAISearch = "sony.quickplay.demo.prefers-voice-ai"
        static let continueWatchingByProfile = "sony.quickplay.demo.continue-watching-by-profile"
        static let favoritesByProfile = "sony.quickplay.demo.favorites-by-profile"
        static let hasCompletedLogin = "sony.quickplay.demo.has-completed-login"
    }

    private let historyThreshold = 6
    private let maxHistoryCount = 24

    private var activeCohort: QuickplayCohort
    private var activePreference: ProfilePreference
    private var activeProfileID: String?
    private var preferenceHistoryByProfile: [String: [String]]
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
        print(
            "[DemoSessionStore] setActiveProfileContext profileID=\(activeProfileID ?? "<nil>"), selectedCohort=\(cohort.rawValue), selectedPreference=\(preference.rawValue), pf=\(cohort.profileFlag)"
        )
        UserDefaults.standard.set(activeProfileID, forKey: StorageKey.activeProfileID)
        UserDefaults.standard.set(cohort.rawValue, forKey: StorageKey.activeCohort)
        UserDefaults.standard.set(preference.rawValue, forKey: StorageKey.activePreference)
    }

    func resetPreferenceHistory(for profileID: UUID?) {
        guard let profileID else { return }
        preferenceHistoryByProfile[profileID.uuidString] = []
        UserDefaults.standard.set(preferenceHistoryByProfile, forKey: StorageKey.preferenceHistoryByProfile)
        print("[DemoSessionStore] resetPreferenceHistory profileID=\(profileID.uuidString)")
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
        let previousCohort = currentCohort()
        let key = historyKey
        var history = preferenceHistoryByProfile[key] ?? []
        history.append(item.inferredPreference.rawValue)
        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }
        preferenceHistoryByProfile[key] = history
        UserDefaults.standard.set(preferenceHistoryByProfile, forKey: StorageKey.preferenceHistoryByProfile)

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

        let updatedCohort = currentCohort()
        print(
            "[DemoSessionStore] recordContentSelection profileKey=\(key), item=\(item.title), inferredPreference=\(item.inferredPreference.rawValue), history=\(history), previousCohort=\(previousCohort.rawValue), updatedCohort=\(updatedCohort.rawValue)"
        )
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
        guard activeCohort != .kids else { return .kids }

        switch dominantPreference {
        case .sports:
            return .sports
        case .realityShows:
            return .realityShows
        case .entertainment:
            return .entertainment
        case nil:
            return activeCohort
        }
    }

    func currentSelectedCohort() -> QuickplayCohort {
        activeCohort
    }

    func currentSelectedPreference() -> ProfilePreference {
        activePreference
    }

    func currentDominantPreference() -> ProfilePreference? {
        dominantPreference
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

    private var dominantPreference: ProfilePreference? {
        let recentPreferences = (preferenceHistoryByProfile[historyKey] ?? [])
            .compactMap(ProfilePreference.init(rawValue:))

        guard !recentPreferences.isEmpty else { return nil }

        let counts = Dictionary(grouping: recentPreferences, by: { $0 }).mapValues(\.count)
        guard let topCount = counts.values.max(), topCount >= historyThreshold else {
            return nil
        }

        let candidates = Set(counts.filter { $0.value == topCount }.map(\.key))
        return recentPreferences.reversed().first(where: { candidates.contains($0) })
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

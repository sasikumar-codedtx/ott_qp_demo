import Foundation

actor DemoSessionStore {
    static let shared = DemoSessionStore()

    private enum StorageKey {
        static let activeCohort = "sony.quickplay.demo.active-cohort"
        static let activePreference = "sony.quickplay.demo.active-preference"
        static let activeProfileID = "sony.quickplay.demo.active-profile-id"
        static let preferenceHistoryByProfile = "sony.quickplay.demo.preference-history-by-profile"
        static let storefrontPolicyClicksByProfile = "sony.quickplay.demo.storefront-policy-clicks-by-profile"
        static let storefrontPolicyOverrideByProfile = "sony.quickplay.demo.storefront-policy-override-by-profile"
        static let prefersVoiceAISearch = "sony.quickplay.demo.prefers-voice-ai"
        static let continueWatchingByProfile = "sony.quickplay.demo.continue-watching-by-profile"
        static let favoritesByProfile = "sony.quickplay.demo.favorites-by-profile"
        static let hasCompletedLogin = "sony.quickplay.demo.has-completed-login"
    }

    private let maxHistoryCount = 24

    private var activeCohort: QuickplayCohort
    private var activePreference: ProfilePreference
    private var activeProfileID: String?
    private var preferenceHistoryByProfile: [String: [String]]
    private var storefrontPolicyClicksByProfile: [String: [String: Int]]
    private var storefrontPolicyOverrideByProfile: [String: String]
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
        storefrontPolicyClicksByProfile = UserDefaults.standard.dictionary(forKey: StorageKey.storefrontPolicyClicksByProfile) as? [String: [String: Int]] ?? [:]
        storefrontPolicyOverrideByProfile = UserDefaults.standard.dictionary(forKey: StorageKey.storefrontPolicyOverrideByProfile) as? [String: String] ?? [:]
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
        storefrontPolicyClicksByProfile[profileID.uuidString] = [:]
        UserDefaults.standard.set(preferenceHistoryByProfile, forKey: StorageKey.preferenceHistoryByProfile)
        UserDefaults.standard.set(storefrontPolicyClicksByProfile, forKey: StorageKey.storefrontPolicyClicksByProfile)
    }

    func storefrontPolicy(for profileID: UUID?) -> StorefrontPolicy {
        let key = profileID?.uuidString ?? historyKey
        if let rawPolicy = storefrontPolicyOverrideByProfile[key],
           let policy = StorefrontPolicy(rawValue: rawPolicy) {
            return policy
        }

        return resolvedStorefrontPolicy(for: key)
    }

    func setStorefrontPolicyOverride(_ policy: StorefrontPolicy, for profileID: UUID?) {
        let key = profileID?.uuidString ?? historyKey
        storefrontPolicyOverrideByProfile[key] = policy.rawValue
        storefrontPolicyClicksByProfile[key] = [:]
        UserDefaults.standard.set(storefrontPolicyOverrideByProfile, forKey: StorageKey.storefrontPolicyOverrideByProfile)
        UserDefaults.standard.set(storefrontPolicyClicksByProfile, forKey: StorageKey.storefrontPolicyClicksByProfile)
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

    func recordContentSelection(_ item: StorefrontItem) {
        let key = historyKey
        if let signal = storefrontPolicySignal(from: item) {
            var counts = storefrontPolicyClicksByProfile[key] ?? [:]
            counts[signal.rawValue, default: 0] += 1
            storefrontPolicyClicksByProfile[key] = counts
            UserDefaults.standard.set(storefrontPolicyClicksByProfile, forKey: StorageKey.storefrontPolicyClicksByProfile)
        }

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

    func currentStorefrontPolicy() -> StorefrontPolicy {
        storefrontPolicy(for: nil)
    }

    func currentStorefrontPolicyAttribute() -> String {
        currentStorefrontPolicy().chrtValue
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

    private enum StorefrontPolicySignal: String {
        case reality
        case sports
    }

    private func storefrontPolicySignal(from item: StorefrontItem) -> StorefrontPolicySignal? {
        let value = [
            item.customSearchCategory,
            item.contentType,
            item.cardType,
            item.customID,
            item.title
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !value.isEmpty else { return nil }

        if value.contains("sport") || value.contains("match") || value.contains("cricket") || value.contains("football") {
            return .sports
        }

        if value.contains("show") || value.contains("reality") {
            return .reality
        }

        return nil
    }

    private func resolvedStorefrontPolicy(for profileKey: String) -> StorefrontPolicy {
        let counts = storefrontPolicyClicksByProfile[profileKey] ?? [:]
        let realityClicks = counts[StorefrontPolicySignal.reality.rawValue] ?? 0
        let sportsClicks = counts[StorefrontPolicySignal.sports.rawValue] ?? 0

        if sportsClicks >= 5 {
            return .sports
        }

        if realityClicks >= 5 {
            if sportsClicks >= 2 {
                return .realitySports
            }
            return .reality
        }

        if sportsClicks >= 2 {
            return .sportsEntertainment
        }

        if realityClicks >= 2 {
            return .realityEntertainment
        }

        return .entertainment
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

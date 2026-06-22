import Foundation

actor DemoSessionStore {
    static let shared = DemoSessionStore()

    private enum StorageKey {
        static let activeCohort = "sony.quickplay.demo.active-cohort"
        static let activePreference = "sony.quickplay.demo.active-preference"
        static let activeProfileID = "sony.quickplay.demo.active-profile-id"
        static let preferenceHistoryByProfile = "sony.quickplay.demo.preference-history-by-profile"
        static let prefersVoiceAISearch = "sony.quickplay.demo.prefers-voice-ai"
    }

    private let historyThreshold = 6
    private let maxHistoryCount = 24

    private var activeCohort: QuickplayCohort
    private var activePreference: ProfilePreference
    private var activeProfileID: String?
    private var preferenceHistoryByProfile: [String: [String]]
    private var prefersVoiceAISearch: Bool

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

    func clearActiveProfileContext() {
        activeProfileID = nil
        activeCohort = .entertainment
        activePreference = .entertainment
        UserDefaults.standard.removeObject(forKey: StorageKey.activeProfileID)
        UserDefaults.standard.set(activeCohort.rawValue, forKey: StorageKey.activeCohort)
        UserDefaults.standard.set(activePreference.rawValue, forKey: StorageKey.activePreference)
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
        var history = preferenceHistoryByProfile[key] ?? []
        history.append(item.inferredPreference.rawValue)
        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }
        preferenceHistoryByProfile[key] = history
        UserDefaults.standard.set(preferenceHistoryByProfile, forKey: StorageKey.preferenceHistoryByProfile)
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
        case .microdramas:
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

    func prefersMicroDramaTab() -> Bool {
        if activeCohort == .kids {
            return false
        }

        if let dominantPreference {
            return dominantPreference == .microdramas
        }

        return activePreference == .microdramas
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
}

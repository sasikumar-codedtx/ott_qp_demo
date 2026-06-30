import Foundation

actor DemoSessionStore {
    static let shared = DemoSessionStore()

    private enum StorageKey {
        static let activeCohort = "sony.quickplay.demo.active-cohort"
        static let activeStorefrontPolicy = "sony.quickplay.demo.active-storefront-policy"
        static let activePreference = "sony.quickplay.demo.active-preference"
        static let activeProfileID = "sony.quickplay.demo.active-profile-id"
        static let activePhoneNumber = "sony.quickplay.demo.active-phone-number"
        static let preferenceHistoryByProfile = "sony.quickplay.demo.preference-history-by-profile"
        static let storefrontPolicyClicksByProfile = "sony.quickplay.demo.storefront-policy-clicks-by-profile"
        static let prefersVoiceAISearch = "sony.quickplay.demo.prefers-voice-ai"
        static let continueWatchingByProfile = "sony.quickplay.demo.continue-watching-by-profile"
        static let favoritesByProfile = "sony.quickplay.demo.favorites-by-profile"
        static let likesByProfile = "sony.quickplay.demo.likes-by-profile"
        static let dislikesByProfile = "sony.quickplay.demo.dislikes-by-profile"
        static let hasCompletedLogin = "sony.quickplay.demo.has-completed-login"
        static let subscribedProfiles = "sony.quickplay.demo.subscribed-profiles"
    }

    private let maxHistoryCount = 24

    private var activeCohort: QuickplayCohort
    private var activeStorefrontPolicy: StorefrontPolicy
    private var activePreference: ProfilePreference
    private var activeProfileID: String?
    private var preferenceHistoryByProfile: [String: [String]]
    private var storefrontPolicyClicksByProfile: [String: [String: Int]]
    private var prefersVoiceAISearch: Bool
    private var continueWatchingByProfile: [String: [StorefrontItem]]
    private var favoritesByProfile: [String: [StorefrontItem]]
    private var likesByProfile: [String: [StorefrontItem]]  // profileID → liked items
    private var dislikesByProfile: [String: [String]]       // profileID → [itemID]
    private var subscribedProfileIDs: Set<String>           // profiles with an active subscription

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
            let rawPolicy = UserDefaults.standard.string(forKey: StorageKey.activeStorefrontPolicy),
            let storedPolicy = StorefrontPolicy(rawValue: rawPolicy)
        {
            activeStorefrontPolicy = storedPolicy
        } else {
            activeStorefrontPolicy = .defaultPolicy(for: activeCohort)
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
        if let data = UserDefaults.standard.data(forKey: StorageKey.likesByProfile),
           let stored = try? JSONDecoder().decode([String: [StorefrontItem]].self, from: data) {
            likesByProfile = stored
        } else {
            likesByProfile = [:]
        }
        if let data = UserDefaults.standard.data(forKey: StorageKey.dislikesByProfile),
           let stored = try? JSONDecoder().decode([String: [String]].self, from: data) {
            dislikesByProfile = stored
        } else {
            dislikesByProfile = [:]
        }

        if UserDefaults.standard.object(forKey: StorageKey.prefersVoiceAISearch) != nil {
            prefersVoiceAISearch = UserDefaults.standard.bool(forKey: StorageKey.prefersVoiceAISearch)
        } else {
            prefersVoiceAISearch = true
        }

        subscribedProfileIDs = Set((UserDefaults.standard.array(forKey: StorageKey.subscribedProfiles) as? [String]) ?? [])
    }

    // MARK: - Subscription (per profile; defaults to not subscribed)

    func isSubscribed(for profileID: UUID? = nil) -> Bool {
        subscribedProfileIDs.contains(profileID?.uuidString ?? historyKey)
    }

    func setSubscribed(_ value: Bool, for profileID: UUID? = nil) {
        let key = profileID?.uuidString ?? historyKey
        if value {
            subscribedProfileIDs.insert(key)
        } else {
            subscribedProfileIDs.remove(key)
        }
        UserDefaults.standard.set(Array(subscribedProfileIDs), forKey: StorageKey.subscribedProfiles)
    }

    func setActiveProfileContext(
        profileID: UUID?,
        cohort: QuickplayCohort,
        preference: ProfilePreference,
        storefrontPolicy: StorefrontPolicy,
        isKidsProfile: Bool = false
    ) {
        let resolvedCohort: QuickplayCohort = isKidsProfile ? .kids : cohort
        let resolvedPolicy: StorefrontPolicy = isKidsProfile ? .defaultPolicy(for: .kids) : storefrontPolicy
        let resolvedPreference: ProfilePreference = isKidsProfile ? QuickplayCohort.kids.defaultPreference : preference

        activeProfileID = profileID?.uuidString
        activeCohort = resolvedCohort
        activeStorefrontPolicy = resolvedPolicy
        activePreference = resolvedPreference
        UserDefaults.standard.set(activeProfileID, forKey: StorageKey.activeProfileID)
        UserDefaults.standard.set(resolvedCohort.rawValue, forKey: StorageKey.activeCohort)
        UserDefaults.standard.set(resolvedPolicy.rawValue, forKey: StorageKey.activeStorefrontPolicy)
        UserDefaults.standard.set(resolvedPreference.rawValue, forKey: StorageKey.activePreference)
        logActiveProfileTapCounts(reason: "profile context selected")
    }

    func resetPreferenceHistory(for profileID: UUID?) {
        guard let profileID else { return }
        preferenceHistoryByProfile[profileID.uuidString] = []
        storefrontPolicyClicksByProfile[profileID.uuidString] = [:]
        UserDefaults.standard.set(preferenceHistoryByProfile, forKey: StorageKey.preferenceHistoryByProfile)
        UserDefaults.standard.set(storefrontPolicyClicksByProfile, forKey: StorageKey.storefrontPolicyClicksByProfile)
    }

    func resetStorefrontPolicyClicks(for profileID: UUID?) {
        guard let profileID else { return }
        storefrontPolicyClicksByProfile[profileID.uuidString] = [:]
        UserDefaults.standard.set(storefrontPolicyClicksByProfile, forKey: StorageKey.storefrontPolicyClicksByProfile)
    }

    func storefrontPolicy(for profileID: UUID?) -> StorefrontPolicy {
        let key = profileID?.uuidString ?? historyKey
        return resolvedStorefrontPolicy(for: key, baselinePolicy: activeStorefrontPolicy)
    }

    func clearActiveProfileContext() {
        activeProfileID = nil
        activeCohort = .entertainment
        activeStorefrontPolicy = .entertainment
        activePreference = .entertainment
        UserDefaults.standard.set(false, forKey: StorageKey.hasCompletedLogin)
        UserDefaults.standard.removeObject(forKey: StorageKey.activeProfileID)
        UserDefaults.standard.set(activeCohort.rawValue, forKey: StorageKey.activeCohort)
        UserDefaults.standard.set(activeStorefrontPolicy.rawValue, forKey: StorageKey.activeStorefrontPolicy)
        UserDefaults.standard.set(activePreference.rawValue, forKey: StorageKey.activePreference)
    }

    func setActivePhoneNumber(_ phone: String) {
        UserDefaults.standard.set(phone, forKey: StorageKey.activePhoneNumber)
    }

    func activePhoneNumber() -> String? {
        UserDefaults.standard.string(forKey: StorageKey.activePhoneNumber)
    }

    func setHasCompletedLogin(_ hasCompletedLogin: Bool) {
        UserDefaults.standard.set(hasCompletedLogin, forKey: StorageKey.hasCompletedLogin)
    }

    func hasCompletedLogin() -> Bool {
        UserDefaults.standard.bool(forKey: StorageKey.hasCompletedLogin)
    }

    func setActiveCohort(_ cohort: QuickplayCohort) {
        activeCohort = cohort
        activeStorefrontPolicy = .defaultPolicy(for: cohort)
        UserDefaults.standard.set(cohort.rawValue, forKey: StorageKey.activeCohort)
        UserDefaults.standard.set(activeStorefrontPolicy.rawValue, forKey: StorageKey.activeStorefrontPolicy)
    }

    func setActivePreference(_ preference: ProfilePreference) {
        activePreference = preference
        UserDefaults.standard.set(preference.rawValue, forKey: StorageKey.activePreference)
    }

    func recordContentSelection(_ item: StorefrontItem) {
        let key = historyKey
        var continueItems = continueWatchingByProfile[key] ?? []
        let progressValue = item.progress ?? 0.32
        let storedItem = item.withProgress(progressValue)
        continueItems.removeAll { $0.id == storedItem.id }
        continueItems.insert(storedItem, at: 0)
        continueItems = deduplicatedItems(continueItems)
        if continueItems.count > maxHistoryCount {
            continueItems.removeLast(continueItems.count - maxHistoryCount)
        }
        continueWatchingByProfile[key] = continueItems
        persistContinueWatching()
    }

    func recordStorefrontCardTap(_ item: StorefrontItem) {
        recordStorefrontPolicySignal(for: item)
    }

    func continueWatchingItems(limit: Int = 20) -> [StorefrontItem] {
        let items = deduplicatedItems(continueWatchingByProfile[historyKey] ?? [])
        continueWatchingByProfile[historyKey] = items
        persistContinueWatching()
        return Array(items.prefix(limit))
    }

    func continueWatchingItems(for profileID: UUID?, limit: Int = 20) -> [StorefrontItem] {
        let key = profileID?.uuidString ?? "guest"
        let items = deduplicatedItems(continueWatchingByProfile[key] ?? [])
        continueWatchingByProfile[key] = items
        persistContinueWatching()
        return Array(items.prefix(limit))
    }

    func continueWatchingItem(id: String) -> StorefrontItem? {
        let items = deduplicatedItems(continueWatchingByProfile[historyKey] ?? [])
        continueWatchingByProfile[historyKey] = items
        persistContinueWatching()
        return items.first(where: { $0.id == id })
    }

    func favoriteItems(limit: Int = 20) -> [StorefrontItem] {
        let items = deduplicatedItems(favoritesByProfile[historyKey] ?? [])
        favoritesByProfile[historyKey] = items
        persistFavorites()
        return Array(items.prefix(limit))
    }

    func favoriteItems(for profileID: UUID?, limit: Int = 20) -> [StorefrontItem] {
        let key = profileID?.uuidString ?? "guest"
        let items = deduplicatedItems(favoritesByProfile[key] ?? [])
        favoritesByProfile[key] = items
        persistFavorites()
        return Array(items.prefix(limit))
    }

    func favoriteIDs() -> Set<String> {
        Set((favoritesByProfile[historyKey] ?? []).map(\.id))
    }

    func toggleFavorite(_ item: StorefrontItem) -> Bool {
        var items = favoritesByProfile[historyKey] ?? []
        if items.contains(where: { $0.id == item.id }) {
            items.removeAll { $0.id == item.id }
            items = deduplicatedItems(items)
            favoritesByProfile[historyKey] = items
            persistFavorites()
            return false
        }

        items.removeAll { $0.id == item.id }
        items.insert(item, at: 0)
        items = deduplicatedItems(items)
        if items.count > maxHistoryCount {
            items.removeLast(items.count - maxHistoryCount)
        }
        favoritesByProfile[historyKey] = items
        persistFavorites()
        return true
    }

    func likedItems(limit: Int = 20) -> [StorefrontItem] {
        let items = deduplicatedItems(likesByProfile[historyKey] ?? [])
        likesByProfile[historyKey] = items
        persistLikes()
        return Array(items.prefix(limit))
    }

    func likedItems(for profileID: UUID?, limit: Int = 20) -> [StorefrontItem] {
        let key = profileID?.uuidString ?? "guest"
        let items = deduplicatedItems(likesByProfile[key] ?? [])
        likesByProfile[key] = items
        persistLikes()
        return Array(items.prefix(limit))
    }

    func likeState(for itemID: String) -> LikeState {
        let key = historyKey
        if (likesByProfile[key] ?? []).contains(where: { $0.id == itemID }) { return .liked }
        if (dislikesByProfile[key] ?? []).contains(itemID) { return .disliked }
        return .none
    }

    /// Cycles: none → liked → disliked → none. Returns new state.
    func cycleLike(for item: StorefrontItem) -> LikeState {
        let key = historyKey
        let current = likeState(for: item.id)
        var likes = likesByProfile[key] ?? []
        var dislikes = dislikesByProfile[key] ?? []
        switch current {
        case .none:
            likes.removeAll { $0.id == item.id }
            likes.insert(item, at: 0)
            likes = deduplicatedItems(likes)
            if likes.count > maxHistoryCount {
                likes.removeLast(likes.count - maxHistoryCount)
            }
            likesByProfile[key] = likes
            persistLikes()
            return .liked
        case .liked:
            likes.removeAll { $0.id == item.id }
            dislikes.removeAll { $0 == item.id }
            dislikes.insert(item.id, at: 0)
            likesByProfile[key] = likes
            dislikesByProfile[key] = dislikes
            persistLikes()
            persistDislikes()
            return .disliked
        case .disliked:
            dislikes.removeAll { $0 == item.id }
            dislikesByProfile[key] = dislikes
            persistDislikes()
            return .none
        }
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
        activeCohort == .kids ? "kids" : currentStorefrontPolicy().chrtValue
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
        case entertainment
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

        return .entertainment
    }

    private func recordStorefrontPolicySignal(for item: StorefrontItem) {
        guard let signal = storefrontPolicySignal(from: item) else { return }
        let key = historyKey
        var counts = storefrontPolicyClicksByProfile[key] ?? [:]
        counts[signal.rawValue, default: 0] += 1
        storefrontPolicyClicksByProfile[key] = counts
        UserDefaults.standard.set(storefrontPolicyClicksByProfile, forKey: StorageKey.storefrontPolicyClicksByProfile)
    }

    private func resolvedStorefrontPolicy(for profileKey: String, baselinePolicy: StorefrontPolicy) -> StorefrontPolicy {
        let counts = storefrontPolicyClicksByProfile[profileKey] ?? [:]
        let entertainmentClicks = counts[StorefrontPolicySignal.entertainment.rawValue] ?? 0
        let realityClicks = counts[StorefrontPolicySignal.reality.rawValue] ?? 0
        let sportsClicks = counts[StorefrontPolicySignal.sports.rawValue] ?? 0
        let totalClicks = entertainmentClicks + realityClicks + sportsClicks

        // Dynamic cohort selection requires more than 5 card clicks to be meaningful.
        // Below that threshold, honour the profile's stored storefront policy directly.
        guard totalClicks > 5 else {
            return baselinePolicy
        }

        let entertainmentShare = Double(entertainmentClicks) / Double(totalClicks)
        let realityShare = Double(realityClicks) / Double(totalClicks)
        let sportsShare = Double(sportsClicks) / Double(totalClicks)
        let pureCohortThreshold = 0.70

        if sportsShare >= pureCohortThreshold {
            return .sports
        }

        if realityShare >= pureCohortThreshold {
            return .reality
        }

        if entertainmentShare >= pureCohortThreshold {
            return .entertainment
        }

        if sportsClicks == realityClicks, realityClicks == entertainmentClicks {
            return .entertainment
        }

        if entertainmentClicks <= sportsClicks, entertainmentClicks <= realityClicks {
            return .realitySports
        }

        if sportsClicks <= entertainmentClicks, sportsClicks <= realityClicks {
            return .realityEntertainment
        }

        return .sportsEntertainment
    }

    private func logActiveProfileTapCounts(reason: String) {
        let key = historyKey
        let counts = storefrontPolicyClicksByProfile[key] ?? [:]
        let entertainmentClicks = counts[StorefrontPolicySignal.entertainment.rawValue] ?? 0
        let realityClicks = counts[StorefrontPolicySignal.reality.rawValue] ?? 0
        let sportsClicks = counts[StorefrontPolicySignal.sports.rawValue] ?? 0
        let totalClicks = entertainmentClicks + realityClicks + sportsClicks
        let effectivePolicy = resolvedStorefrontPolicy(for: key, baselinePolicy: activeStorefrontPolicy)

        print("""
        [StorefrontPolicy][TapCounts]
        reason: \(reason)
        profileID: \(activeProfileID ?? "guest")
        baselinePolicy: \(activeStorefrontPolicy.rawValue) chrt=\(activeStorefrontPolicy.chrtValue)
        effectivePolicy: \(effectivePolicy.rawValue) chrt=\(effectivePolicy.chrtValue)
        dynamicEnabled: \(totalClicks > 5)
        entertainment: \(entertainmentClicks)
        reality: \(realityClicks)
        sports: \(sportsClicks)
        total: \(totalClicks)
        """)
    }

    private func persistContinueWatching() {
        guard let data = try? JSONEncoder().encode(continueWatchingByProfile) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.continueWatchingByProfile)
    }

    private func persistFavorites() {
        guard let data = try? JSONEncoder().encode(favoritesByProfile) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.favoritesByProfile)
    }

    private func persistLikes() {
        guard let data = try? JSONEncoder().encode(likesByProfile) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.likesByProfile)
    }

    private func persistDislikes() {
        guard let data = try? JSONEncoder().encode(dislikesByProfile) else { return }
        UserDefaults.standard.set(data, forKey: StorageKey.dislikesByProfile)
    }

    private func deduplicatedItems(_ items: [StorefrontItem]) -> [StorefrontItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }

}

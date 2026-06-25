import SwiftUI

struct SettingsView: View {
    let activeProfile: Profile?
    let profiles: [Profile]
    let isVoiceAISearchEnabled: Bool
    let onBack: () -> Void
    let onSignOut: () -> Void
    let onSelectProfile: (Profile) -> Void
    let onVoiceAISearchChange: (Bool) -> Void
    let onAddProfile: () -> Void
    let onEditProfiles: () -> Void

    @State private var navigationPath: [SettingsScreen] = []
    @State private var showsProfileSwitch = false
    @State private var activeAudioSheet: AudioSelectionSheet?
    @State private var hasActiveSubscription: Bool
    @State private var selectedAudioQuality = "Dolby 5.1 ( Default )"
    @State private var selectedSubtitleLanguage = "English ( Default )"
    @State private var selectedAudioTrack = "Hindi ( Default )"
    @State private var autoplayPreviews = true
    @State private var pipEnabled = true
    @State private var streamOverWiFiOnly = false
    @State private var imageCacheStatus = "Poster cache capped at 500 MB"

    init(
        activeProfile: Profile?,
        profiles: [Profile],
        isVoiceAISearchEnabled: Bool,
        onBack: @escaping () -> Void,
        onSignOut: @escaping () -> Void,
        onSelectProfile: @escaping (Profile) -> Void,
        onVoiceAISearchChange: @escaping (Bool) -> Void,
        onAddProfile: @escaping () -> Void,
        onEditProfiles: @escaping () -> Void
    ) {
        self.activeProfile = activeProfile
        self.profiles = profiles
        self.isVoiceAISearchEnabled = isVoiceAISearchEnabled
        self.onBack = onBack
        self.onSignOut = onSignOut
        self.onSelectProfile = onSelectProfile
        self.onVoiceAISearchChange = onVoiceAISearchChange
        self.onAddProfile = onAddProfile
        self.onEditProfiles = onEditProfiles
        _hasActiveSubscription = State(initialValue: AppEnvironment.Demo.hasActiveSubscription)
    }

    private var currentProfile: Profile? {
        activeProfile ?? profiles.first
    }

    private var currentScreen: SettingsScreen {
        navigationPath.last ?? .root
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                settingsPage(for: currentScreen, topInset: proxy.safeAreaInsets.top)

                overlayLayer
            }
            .routeNavigationOverlay(title: currentScreen.title, onBack: handleBack) {
                if currentScreen == .root {
                    RouteNavigationIconButton(icon: AppIcons.Action.headphones, action: {})
                }
            }
            .animation(.easeInOut(duration: 0.22), value: currentScreen)
            .animation(.easeInOut(duration: 0.22), value: showsProfileSwitch)
            .animation(.easeInOut(duration: 0.22), value: activeAudioSheet)
        }
    }

    private func settingsPage(for screen: SettingsScreen, topInset: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: UIConstants.Spacing.xl) {
                pageContent(for: screen)
            }
            .padding(.horizontal, UIConstants.Spacing.lg)
            .padding(.top, max(topInset + 72, 88))
            .padding(.bottom, 40)
        }
        .background(Color.clear)
    }

    @ViewBuilder
    private func pageContent(for screen: SettingsScreen) -> some View {
        switch screen {
        case .root:
            rootPage
        case .account:
            accountPage
        case .manageSubscription:
            manageSubscriptionPage
        case .flipkart:
            flipkartPage
        case .activateTV:
            activateTVPage
        case .videoSettings:
            videoSettingsPage
        case .audioSettings:
            audioSettingsPage
        case .faqs:
            faqsPage
        case .terms:
            documentPage(
                title: "Terms and Conditions",
                sections: [
                    SettingsDocumentSection(title: "Membership", body: "This build uses mocked profile creation and mocked subscription control. The visual flow matches Sony LIV, while actions are local to the demo."),
                    SettingsDocumentSection(title: "Usage", body: "Use the app for design validation, API integration planning, and interaction walkthroughs. Streaming, billing, and purchase flows are not live in this prototype."),
                    SettingsDocumentSection(title: "Profiles", body: "Profile creation, cohort choice, and parental toggles are stored locally in demo state so the experience feels functional during review.")
                ]
            )
        case .privacy:
            documentPage(
                title: "Privacy Polices",
                sections: [
                    SettingsDocumentSection(title: "Data in this POC", body: "This build stores mocked profile data, avatar choice, and settings selections locally on the device for demonstration."),
                    SettingsDocumentSection(title: "Favorites", body: "Favorites remain mocked in this build and are not synced to a server yet. The same applies to some account and subscription actions."),
                    SettingsDocumentSection(title: "Next Step", body: "Once APIs are connected, this structure is ready to swap local state for live endpoints without changing the page hierarchy.")
                ]
            )
        }
    }

    private var rootPage: some View {
        VStack(spacing: 32) {
            subscriptionCard

            VStack(spacing: 20) {
                settingsGroup([
                    SettingsRow(icon: AppIcons.Action.person, title: AppStrings.Profile.account, subtitle: "Personal details & parental controls", destination: .account),
                    SettingsRow(icon: AppIcons.Action.receipt, title: AppStrings.Profile.manageSubscription, subtitle: "view purchase history and upgrade plans", destination: .manageSubscription),
                    SettingsRow(icon: AppIcons.Action.bolt, title: AppStrings.Profile.flipkart, subtitle: "Redeem Sony LIV offers and subscription codes", destination: .flipkart),
                    SettingsRow(icon: AppIcons.Action.tv, title: AppStrings.Profile.activateTV, subtitle: "Connect and manage TV settings", destination: .activateTV)
                ])

                settingsGroup([
                    SettingsRow(icon: AppIcons.Action.video, title: AppStrings.Profile.videoSettings, subtitle: "Video quality, streaming, PIP mode", destination: .videoSettings),
                    SettingsRow(icon: AppIcons.Action.headphones, title: AppStrings.Profile.audioSettings, subtitle: "Audio, language and subtitle preference", destination: .audioSettings)
                ])

                settingsGroup([
                    SettingsRow(icon: AppIcons.Action.question, title: AppStrings.Profile.faqs, subtitle: nil, destination: .faqs),
                    SettingsRow(icon: AppIcons.Action.doc, title: AppStrings.Profile.terms, subtitle: nil, destination: .terms),
                    SettingsRow(icon: AppIcons.Action.shield, title: AppStrings.Profile.privacy, subtitle: nil, destination: .privacy),
                    SettingsRow(icon: AppIcons.Action.logout, title: AppStrings.Profile.signOut, subtitle: nil, accent: Color(hex: "FF9800"), destination: nil)
                ])
            }

            footer
        }
    }

    private var accountPage: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                ProfileAvatarView(
                    imageName: currentProfile?.imageName,
                    fallbackGlyph: currentProfile?.fallbackGlyph ?? "P",
                    size: 76
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(currentProfile?.name ?? "Profile")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Text(AppEnvironment.Demo.supportPhoneNumber)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.56))

                    Text("Profile creation is mocked in this POC.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "F5B919"))
                }

                Spacer()
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )

            settingsGroup([
                SettingsRow(icon: "arrow.trianglehead.2.clockwise", title: "Switch Profile", subtitle: "Open profile chooser from settings", destination: nil),
                SettingsRow(icon: "pencil.line", title: "Edit Profiles", subtitle: "Open the mocked create and edit flow", destination: nil),
                SettingsRow(icon: "heart", title: "Favorites", subtitle: "Favorites are mocked in this build", destination: nil),
                SettingsRow(icon: "lock", title: "Parental Controls", subtitle: "PIN protection is mocked for now", destination: nil)
            ], customAction: { title in
                switch title {
                case "Switch Profile":
                    showsProfileSwitch = true
                case "Edit Profiles":
                    onEditProfiles()
                default:
                    break
                }
            })

            VStack(alignment: .leading, spacing: 12) {
                Text("Current Profile Preferences")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                accountDetailRow(title: "Preferred Cohort", value: currentProfile?.preference.displayName ?? "Entertainment")
                accountDetailRow(title: "Languages", value: formattedLanguages)
                accountDetailRow(title: "Mode", value: currentProfile?.isKidsProfile == true ? "Kids Profile" : "Standard")
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )

            aiSearchPreferenceCard
        }
    }

    private var aiSearchPreferenceCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Voice AI Search")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text(isVoiceAISearchEnabled ? "Mic opens listening AI search flow" : "Mic opens text AI prompt flow")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            Spacer()

            Toggle(
                "",
                isOn: Binding(
                    get: { isVoiceAISearchEnabled },
                    set: { onVoiceAISearchChange($0) }
                )
            )
            .labelsHidden()
            .toggleStyle(SonyLIVPillToggleStyle())
        }
        .padding(18)
        .background(
            LiquidGlassBackground(cornerRadius: 22, tone: .dark)
        )
    }

    private var manageSubscriptionPage: some View {
        VStack(spacing: 18) {
            subscriptionDetailHero

            VStack(alignment: .leading, spacing: 12) {
                Text("Available Plans")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                planCard(title: "LIV Premium", subtitle: "4K UHD • Dolby Atmos • Ads Free", price: "Rs. 999 / year", featured: true)
                planCard(title: "LIV Basic", subtitle: "HD streaming across mobile devices", price: "Rs. 299 / year", featured: false)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Purchase History")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                documentBlock(text: hasActiveSubscription ? "Premium activated on this device for demo review.\nPayment method: Mock UPI\nRenewal: 01 Jan 2027" : "No purchases yet in this mocked build.\nTap the button below to preview the active subscription variant.")
            }

            Button(action: {
                hasActiveSubscription.toggle()
            }) {
                Text(hasActiveSubscription ? "Disable Mock Subscription" : "Activate Mock Premium")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "151424"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(LiquidGlassBackground(cornerRadius: 12, tone: .light, isHighlighted: true))
            }
            .buttonStyle(LiquidButtonPressStyle())
        }
    }

    private var flipkartPage: some View {
        VStack(spacing: 18) {
            documentBlock(
                title: "Offers & Redeem Codes",
                text: "Use this mocked screen to preview Sony LIV promotional offers, voucher redemption, and partner-code activation. The live redemption flow is not connected yet, but the structure is ready for integration."
            )

            planCard(title: "Promo Code", subtitle: "Apply a subscription voucher or campaign code", price: "Redeem", featured: true)
            planCard(title: "Partner Offer", subtitle: "Preview bundled or campaign-based subscription benefits", price: "Coming Soon", featured: false)

            Button(action: {}) {
                Text("Apply Mock Offer")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "151424"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(LiquidGlassBackground(cornerRadius: 12, tone: .light, isHighlighted: true))
            }
            .buttonStyle(LiquidButtonPressStyle())
        }
    }

    private var activateTVPage: some View {
        VStack(spacing: 18) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "17113A"), Color(hex: "40160E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 210)
                .overlay(
                    VStack(spacing: 14) {
                        Image(systemName: "tv")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(Color(hex: "F5B919"))
                        Text("Use code `LIV8Q9` on your TV")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Open Sony LIV on your television, choose Activate TV, and enter this code.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.62))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                )

            documentBlock(
                title: "How it works",
                text: "1. Launch Sony LIV on TV\n2. Tap Activate TV\n3. Enter the device code shown above\n4. The TV will pair with this mocked profile"
            )
        }
    }

    private var videoSettingsPage: some View {
        VStack(spacing: 18) {
            settingsGroup([
                SettingsRow(icon: "sparkles.tv", title: "Streaming Quality", subtitle: "High", destination: nil),
                SettingsRow(icon: "play.rectangle", title: "Autoplay Previews", subtitle: autoplayPreviews ? "On" : "Off", destination: nil),
                SettingsRow(icon: "pip", title: "Picture in Picture", subtitle: pipEnabled ? "Enabled" : "Disabled", destination: nil),
                SettingsRow(icon: "wifi", title: "Wi-Fi only streaming", subtitle: streamOverWiFiOnly ? "On" : "Off", destination: nil),
                SettingsRow(icon: "trash", title: "Clear Image Cache", subtitle: imageCacheStatus, destination: nil)
            ], customAction: { title in
                switch title {
                case "Autoplay Previews":
                    autoplayPreviews.toggle()
                case "Picture in Picture":
                    pipEnabled.toggle()
                case "Wi-Fi only streaming":
                    streamOverWiFiOnly.toggle()
                case "Clear Image Cache":
                    imageCacheStatus = "Clearing cached posters..."
                    ImageCacheManager.clear {
                        Task { @MainActor in
                            imageCacheStatus = "Image cache cleared"
                        }
                    }
                default:
                    break
                }
            })

            documentBlock(
                title: "Playback",
                text: "This page is mocked and keeps local state only. Once the video settings API is wired, the toggles can map directly onto persisted user preferences."
            )
        }
    }

    private var audioSettingsPage: some View {
        VStack(spacing: 18) {
            settingsGroup([
                SettingsRow(icon: "waveform", title: "Audio Quality", subtitle: selectedAudioQuality, destination: nil),
                SettingsRow(icon: "captions.bubble", title: "Subtitle Preference", subtitle: selectedSubtitleLanguage, destination: nil),
                SettingsRow(icon: AppIcons.Action.headphones, title: "Audio Track", subtitle: selectedAudioTrack, destination: nil)
            ], customAction: { title in
                switch title {
                case "Audio Quality":
                    activeAudioSheet = .audioQuality
                case "Subtitle Preference":
                    activeAudioSheet = .subtitlePreference
                case "Audio Track":
                    activeAudioSheet = .audioTrack
                default:
                    break
                }
            })
        }
    }

    private var faqsPage: some View {
        VStack(spacing: 16) {
            faqCard(question: "Is this a live settings flow?", answer: "This screen stack is hardcoded for the POC, but it is structured so each page can be hooked to real APIs later.")
            faqCard(question: "Are profile creation and favorites connected?", answer: "Not yet. Both profile creation and favorites are mocked right now, as requested.")
            faqCard(question: "Will audio and subtitle choices persist?", answer: "In this build they persist only while the screen is alive. We can wire them to stored settings or backend preferences next.")
        }
    }

    private func documentPage(title: String, sections: [SettingsDocumentSection]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sections) { section in
                documentBlock(title: section.title, text: section.body)
            }
        }
    }

    private var overlayLayer: some View {
        ZStack(alignment: .bottom) {
            if showsProfileSwitch || activeAudioSheet != nil {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.28)

                    Color.black.opacity(0.62)
                }
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        showsProfileSwitch = false
                        activeAudioSheet = nil
                    }
            }

            if showsProfileSwitch {
                ProfileSwitchSheetView(
                    profiles: Array(profiles.prefix(5)),
                    selectedProfile: currentProfile,
                    onSelect: { profile in
                        onSelectProfile(profile)
                        showsProfileSwitch = false
                    },
                    onAddProfile: {
                        showsProfileSwitch = false
                        onAddProfile()
                    },
                    onEditProfiles: {
                        showsProfileSwitch = false
                        onEditProfiles()
                    },
                    onClose: {
                        showsProfileSwitch = false
                    }
                )
                .transition(.move(edge: .bottom))
            }

            if let sheet = activeAudioSheet {
                SettingsChoiceSheet(
                    title: sheet.title,
                    options: sheet.options,
                    selectedValue: selectedValue(for: sheet),
                    onClose: {
                        activeAudioSheet = nil
                    },
                    onSelect: { value in
                        applySelection(value, for: sheet)
                    }
                )
            }
        }
    }

    private var subscriptionCard: some View {
        VStack(spacing: 0) {
            Button {
                navigationPath.append(.manageSubscription)
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(hasActiveSubscription ? Color(hex: "FF985F") : Color(hex: "F5B919"))
                        Image(systemName: hasActiveSubscription ? AppIcons.Action.crown : "exclamationmark")
                            .font(.system(size: hasActiveSubscription ? 20 : 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(hasActiveSubscription ? "Premium Subscription" : "No Active Subscription")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(.white)

                        Text(hasActiveSubscription ? "\(AppEnvironment.Demo.supportPhoneNumber) | Valid upto: 01 Jan 2027" : AppEnvironment.Demo.supportPhoneNumber)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.68))
                    }

                    Spacer()

                    Image(systemName: AppIcons.Navigation.next)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 18)
                .frame(height: 74)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: hasActiveSubscription
                                    ? [Color(hex: "FF995E"), Color(hex: "B58BEA"), Color(hex: "5E1633")]
                                    : [Color(hex: "1A1345"), Color(hex: "4B1A0E")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(hasActiveSubscription ? Color(hex: "C28CFF") : Color(hex: "F5B919"), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(LiquidButtonPressStyle())

            Text("Upgrade to 4k UHD • Dolby Atoms • Ads Free")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color(hex: "F8B326"))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .offset(y: -6)
                .padding(.horizontal, 4)
                .padding(.bottom, -6)
        }
    }

    private var subscriptionDetailHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(hasActiveSubscription ? Color(hex: "F39A56") : Color(hex: "F5B919"))
                    Image(systemName: hasActiveSubscription ? AppIcons.Action.crown : "exclamationmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(hasActiveSubscription ? "Premium Subscription" : "No Active Subscription")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text(hasActiveSubscription ? "\(AppEnvironment.Demo.supportPhoneNumber) | Valid upto: 01 Jan 2027" : AppEnvironment.Demo.supportPhoneNumber)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.62))
                }
            }

            Text("Upgrade to 4k UHD • Dolby Atoms • Ads Free")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "151424"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "F5B919"))
                )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: hasActiveSubscription
                            ? [Color(hex: "FF995E"), Color(hex: "B58BEA"), Color(hex: "5E1633")]
                            : [Color(hex: "1A1345"), Color(hex: "4B1A0E")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }

    private func settingsGroup(_ rows: [SettingsRow], customAction: ((String) -> Void)? = nil) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                Button {
                    if let destination = row.destination {
                        navigationPath.append(destination)
                    } else if row.title == AppStrings.Profile.signOut {
                        onSignOut()
                    } else {
                        customAction?(row.title)
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: row.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(row.accent ?? Color.white.opacity(0.82))
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(row.accent ?? .white)
                            if let subtitle = row.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(Color.white.opacity(0.38))
                            }
                        }

                        Spacer()

                        if row.title != AppStrings.Profile.signOut {
                            Image(systemName: AppIcons.Navigation.next)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: row.subtitle == nil ? 67 : 70)
                    .contentShape(Rectangle())
                }
                .buttonStyle(LiquidButtonPressStyle())

                if index < rows.count - 1 {
                    Divider()
                        .overlay(Color.black.opacity(0.55))
                }
            }
        }
        .background(
            LiquidGlassBackground(cornerRadius: 22, tone: .dark)
        )
    }

    private func planCard(title: String, subtitle: String, price: String, featured: Bool) -> some View {
        HStack(spacing: 14) {
            if featured {
                LogoGlowView(size: 44, glowScale: 1.8)
                    .frame(width: 54, height: 54)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.07))
                    Image(systemName: AppIcons.Action.crown)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.72))
                }
                .frame(width: 54, height: 54)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            HStack {
                Text(price)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(featured ? Color(hex: "F5B919") : .white.opacity(0.8))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: featured
                            ? [Color(hex: "311647"), Color(hex: "160C21"), Color(hex: "2B130E")]
                            : [Color.white.opacity(0.07), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(featured ? Color(hex: "F5B919").opacity(0.65) : Color.white.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: featured ? Color(hex: "F5A623").opacity(0.18) : Color.clear, radius: 18, x: 0, y: 0)
        )
    }

    private func documentBlock(title: String? = nil, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.62))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func faqCard(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            Text(answer)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.6))
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func accountDetailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            LogoGlowView(size: 92, glowScale: 1.45)

            Text(AppStrings.Profile.sonyFooter + " \u{2665}")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }

    private var formattedLanguages: String {
        let items = currentProfile?.preferredLanguages.map(\.englishTitle) ?? []
        return items.isEmpty ? "English" : items.joined(separator: ", ")
    }

    private func handleBack() {
        if activeAudioSheet != nil {
            activeAudioSheet = nil
            return
        }

        if navigationPath.isEmpty {
            onBack()
        } else {
            navigationPath.removeLast()
        }
    }

    private func applySelection(_ value: String, for sheet: AudioSelectionSheet) {
        switch sheet {
        case .audioQuality:
            selectedAudioQuality = value
        case .subtitlePreference:
            selectedSubtitleLanguage = value
        case .audioTrack:
            selectedAudioTrack = value
        }
        activeAudioSheet = nil
    }

    private func selectedValue(for sheet: AudioSelectionSheet) -> String {
        switch sheet {
        case .audioQuality:
            return selectedAudioQuality
        case .subtitlePreference:
            return selectedSubtitleLanguage
        case .audioTrack:
            return selectedAudioTrack
        }
    }
}

private enum SettingsScreen: Hashable {
    case root
    case account
    case manageSubscription
    case flipkart
    case activateTV
    case videoSettings
    case audioSettings
    case faqs
    case terms
    case privacy

    var title: String {
        switch self {
        case .root:
            return "Settings"
        case .account:
            return "Account"
        case .manageSubscription:
            return "Manage Subscription"
        case .flipkart:
            return "Offers"
        case .activateTV:
            return "Activate TV"
        case .videoSettings:
            return "Video settings"
        case .audioSettings:
            return "Audio settings"
        case .faqs:
            return "FAQs"
        case .terms:
            return "Terms and Conditions"
        case .privacy:
            return "Privacy Polices"
        }
    }
}

private enum AudioSelectionSheet: Equatable {
    case audioQuality
    case subtitlePreference
    case audioTrack

    var title: String {
        switch self {
        case .audioQuality:
            return "Audio Quality"
        case .subtitlePreference:
            return "Subtitle Preference"
        case .audioTrack:
            return "Audio Track"
        }
    }

    var options: [String] {
        switch self {
        case .audioQuality:
            return ["SD", "HD", "Dolby 5.1 ( Default )"]
        case .subtitlePreference:
            return ["English", "Kannad", "Telugu", "Malay", "Hindi (Default)"]
        case .audioTrack:
            return ["English", "Kannad", "Telugu", "Malay", "Hindi (Default)"]
        }
    }

}

private struct SettingsRow: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String?
    var accent: Color? = nil
    let destination: SettingsScreen?
}

private struct SettingsDocumentSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

private struct SonyLIVPillToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                configuration.isOn.toggle()
            }
        } label: {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: configuration.isOn
                                ? [Color(hex: "FFB347"), Color(hex: "FF5E00")]
                                : [Color.white.opacity(0.16), Color.white.opacity(0.06)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(configuration.isOn ? Color(hex: "FFCF82").opacity(0.7) : Color.white.opacity(0.12), lineWidth: 1)
                    )

                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: Color.black.opacity(0.28), radius: 8, x: 0, y: 4)
                    .padding(3)
            }
            .frame(width: 54, height: 30)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

private struct SettingsChoiceSheet: View {
    let title: String
    let options: [String]
    let selectedValue: String
    let onClose: () -> Void
    let onSelect: (String) -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.82))
                            .frame(width: 24, height: 24)
                            .background(LiquidGlassCircleBackground(tone: .dark))
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                }

                VStack(spacing: 4) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            onSelect(option)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedValue == option ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white)
                                Text(option)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 54)
                            .background(
                                LiquidGlassBackground(cornerRadius: 12, tone: .dark, isHighlighted: selectedValue == option)
                            )
                        }
                        .buttonStyle(LiquidButtonPressStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 26)
            .padding(.bottom, 30)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "191919"), Color(hex: "070708")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 54, height: 5)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 6)
        }
        .ignoresSafeArea()
    }
}

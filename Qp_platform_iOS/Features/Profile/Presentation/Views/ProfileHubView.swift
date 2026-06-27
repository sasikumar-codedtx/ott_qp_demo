import SwiftUI

struct ProfileHubView: View {
    @ObservedObject var viewModel: ProfileHubViewModel
    let profiles: [Profile]
    let onBack: () -> Void
    let onOpenSettings: () -> Void
    let onSwitchProfile: () -> Void
    let onAddProfile: () -> Void
    let onEditProfiles: () -> Void
    let onSelectProfile: (Profile) -> Void
    let onSelectItem: (StorefrontItem) -> Void
    @State private var showsProfileSwitch = false

    var body: some View {
        GeometryReader { proxy in
            content(topInset: proxy.safeAreaInsets.top)
            .ignoresSafeArea(edges: .top)
        }
        .overlay {
            if showsProfileSwitch {
                ZStack(alignment: .bottom) {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.28)

                        Color.black.opacity(0.62)
                    }
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        showsProfileSwitch = false
                    }

                    ProfileSwitchSheetView(
                        profiles: profiles,
                        selectedProfile: viewModel.selectedProfile,
                        onSelect: { profile in
                            showsProfileSwitch = false
                            onSelectProfile(profile)
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
                .ignoresSafeArea()
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: showsProfileSwitch)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private func header(topInset: CGFloat) -> some View {
        GeometryReader { proxy in
            let screenWidth = max(proxy.size.width, 320)
            let baseHeaderHeight = 248 + topInset
            let scrollMinY = proxy.frame(in: .named("profileHubScroll")).minY
            let pullDistance = max(scrollMinY, 0)
            let scrollDistance = max(-scrollMinY, 0)
            let imageHeight = baseHeaderHeight + pullDistance
            let imageOffset = scrollMinY > 0 ? -pullDistance : -scrollDistance * 0.34

            ZStack(alignment: .top) {
                Image("proBg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: imageHeight)
                    .scaleEffect(1 + min(pullDistance / 900, 0.08), anchor: .top)
                    .clipped()
                    .offset(y: imageOffset)

                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.12), Color.black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: screenWidth, height: imageHeight)
                .offset(y: scrollMinY > 0 ? -pullDistance : imageOffset)

                // Avatar + profile switcher at bottom of hero
                VStack {
                    Spacer()
                    HStack(spacing: 14) {
                        ProfileAvatarView(
                            imageName: viewModel.displayedProfileImageName,
                            fallbackGlyph: String(viewModel.displayedProfileName.prefix(1)).uppercased(),
                            size: 89.636
                        )

                        Button(action: {
                            showsProfileSwitch = true
                        }) {
                            HStack(spacing: 6) {
                                Text(viewModel.displayedProfileName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)

                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(LiquidButtonPressStyle())
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                    .padding(.bottom, 6)
                }
                .frame(width: screenWidth, height: baseHeaderHeight)
            }
        }
        .frame(height: 248 + topInset)
    }

    @ViewBuilder
    private func content(topInset: CGFloat) -> some View {
        if viewModel.isLoading && viewModel.sections.isEmpty {
            LoadingView()
        } else if let errorMessage = viewModel.errorMessage, viewModel.sections.isEmpty {
            ErrorView(title: AppStrings.Profile.yourProfiles, message: errorMessage, onRetry: {
                Task { await viewModel.loadIfNeeded() }
            })
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: UIConstants.Spacing.xl) {
                    header(topInset: topInset)

                    if let leadingSection = viewModel.leadingSection {
                        profileRailSection(leadingSection, style: .poster, width: 188)
                    }

                    downloadsCard
                        .padding(.horizontal, UIConstants.Spacing.lg)

                    if let clipsSection = viewModel.sections.first(where: { $0.id == "clips" }) {
                        clipsRailSection(clipsSection)
                    }

                    ForEach(viewModel.trailingSections.filter { $0.id != "clips" }) { section in
                        StorefrontSectionView(
                            section: section,
                            isHomeTab: false,
                            cohort: viewModel.selectedProfile?.quickplayCohort ?? .entertainment,
                            heroVariant: .carousel,
                            topChromeHeight: 0,
                            favoriteIDs: [],
                            onViewAll: nil,
                            onSelectItem: onSelectItem,
                            onToggleFavorite: { _ in }
                        )
                    }

                    if !AppEnvironment.Demo.hasActiveSubscription {
                        upgradeCard
                            .padding(.horizontal, UIConstants.Spacing.lg)
                    }

                    footer
                }
                .padding(.bottom, UIConstants.Spacing.xxl)
            }
            .coordinateSpace(name: "profileHubScroll")
            .background(Color.black.ignoresSafeArea())
        }
    }

    private var downloadsCard: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                Image(systemName: AppIcons.Action.download)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppStrings.Profile.downloads)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(AppStrings.Profile.downloadsSubtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.42))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: AppIcons.Navigation.next)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.62))
            }
            .padding(.horizontal, 16)
            .frame(height: 89, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "171717"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private var upgradeCard: some View {
        Button(action: {}) {
            ZStack(alignment: .topLeading) {
                Image("upgradebg")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .allowsHitTesting(false)

//                Color.black.opacity(0.35)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Upgrade\nyour Plan")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                        .lineSpacing(2)
                        .shadow(color: .black.opacity(0.25), radius: 25, x: 0, y: 4)
                        .padding(.top, 20)
                        .padding(.leading, UIConstants.Spacing.xl)

                    upgradeFeaturesGrid
                        .padding(.top, 24)
                        .padding(.horizontal, UIConstants.Spacing.xl)

                    Spacer(minLength: 14)

                    upgradeCTAButton
                        .padding(.horizontal, UIConstants.Spacing.xl)

                    Button(action: {}) {
                        HStack(spacing: 5) {
                            Text("Subscribe to Basic plan")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.white.opacity(0.2))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.2))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(LiquidButtonPressStyle())
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 374)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "FFAD09"), lineWidth: 2)
            )
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
    private var upgradeFeaturesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            upgradeFeatureRow(icon: "desktopcomputer", prefix: "Upto ", bold: "5 devices", suffix: "")
            upgradeFeatureRow(icon: "tv.fill", prefix: "", bold: "Reginal", suffix: " daily shows")
            upgradeFeatureRow(icon: "film.fill", prefix: "High ", bold: "Audio & Video", suffix: " Quality")
            upgradeFeatureRow(icon: "hand.raised.fill", prefix: "", bold: "Ads Free", suffix: " Movies and shows")
        }
    }

    private func upgradeFeatureRow(icon: String, prefix: String, bold: String, suffix: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.88))
                .frame(width: 20)

            (Text(prefix).font(.system(size: 11, weight: .regular))
             + Text(bold).font(.system(size: 11, weight: .bold))
             + Text(suffix).font(.system(size: 11, weight: .regular)))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private var upgradeCTAButton: some View {
        HStack(spacing: 6) {
            Text("Became Premium Member Now")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: "FFD24B"), .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "FF5E00"))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.31), lineWidth: 1)
                    .padding(1)
            }
        )
    }

    private var footer: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            LogoGlowView(size: 72, glowScale: 1.45)

            Text(AppStrings.Profile.sonyFooter)
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.44))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, UIConstants.Spacing.md)
    }

    private func profileRailSection(_ section: StorefrontSection, style: StorefrontCardStyle, width: CGFloat) -> some View {
        let ratio: CGFloat = style == .short ? (9 / 16) : (2 / 3)
        let size = CGSize(width: width, height: width / ratio)
        let layout = StorefrontCardLayout(size: size, overlayHeight: style == .short ? 0 : 64, visibleCount: 2)

        return VStack(alignment: .leading, spacing: 11) {
            SectionHeaderView(title: section.title)
                .padding(.horizontal, UIConstants.Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(section.items) { item in
                        StorefrontCardView(item: item, style: style, layout: layout, rank: nil, onSelect: onSelectItem)
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
            }
        }
    }

    private func clipsRailSection(_ section: StorefrontSection) -> some View {
        let cardWidth: CGFloat = 275
        let cardHeight: CGFloat = cardWidth * 16 / 9
        let size = CGSize(width: cardWidth, height: cardHeight)
        let layout = StorefrontCardLayout(size: size, overlayHeight: 0, visibleCount: 2)

        return VStack(alignment: .leading, spacing: 11) {
            SectionHeaderView(title: section.title)
                .padding(.horizontal, UIConstants.Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(section.items) { item in
                        ZStack {
                            StorefrontCardView(item: item, style: .short, layout: layout, rank: nil, onSelect: onSelectItem)

                            RoundedRectangle(cornerRadius: StorefrontRailMetrics.cardCornerRadius, style: .continuous)
                                .fill(Color.black.opacity(0.36))
                                .overlay {
                                    Image(systemName: AppIcons.Action.playCircle)
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.92), .white.opacity(0.18))
                                }
                                .frame(width: cardWidth, height: cardHeight)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.lg)
            }
        }
    }
}

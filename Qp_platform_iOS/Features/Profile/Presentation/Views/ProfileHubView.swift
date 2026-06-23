import SwiftUI

struct ProfileHubView: View {
    @ObservedObject var viewModel: ProfileHubViewModel
    let profiles: [Profile]
    let onBack: () -> Void
    let onOpenSettings: () -> Void
    let onSwitchProfile: () -> Void
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
                ZStack {
                    Color.black.opacity(0.78)
                        .ignoresSafeArea()
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
                        onEditProfiles: {
                            showsProfileSwitch = false
                            onSwitchProfile()
                        },
                        onClose: {
                            showsProfileSwitch = false
                        }
                    )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showsProfileSwitch)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private func header(topInset: CGFloat) -> some View {
        GeometryReader { proxy in
            let screenWidth = max(proxy.size.width, 320)
            let headerHeight = 248 + topInset

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Image("proBg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: screenWidth, height: headerHeight)
                        .clipped()

                    LinearGradient(
                        colors: [Color.black.opacity(0.12), Color.black.opacity(0.18), Color.black.opacity(0.86)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: headerHeight)

                    VStack {
                        Spacer()

                        HStack(spacing: 14) {
                            ProfileAvatarView(
                                imageName: viewModel.displayedProfileImageName,
                                fallbackGlyph: String(viewModel.displayedProfileName.prefix(1)).uppercased(),
                                size: 58
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )

                            Button(action: {
                                showsProfileSwitch = true
                            }) {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(viewModel.displayedProfileName)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.white)

                                        Text("Switch Profile")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(Color.white.opacity(0.72))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 58)
                                .background(LiquidGlassBackground(cornerRadius: 18, tone: .dark))
                            }
                            .buttonStyle(LiquidButtonPressStyle())
                        }
                        .padding(.horizontal, UIConstants.Spacing.lg)
                        .padding(.bottom, 14)
                    }
                }
                .frame(height: headerHeight)
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
                        profileRailSection(clipsSection, style: .short, width: 188)
                    }

                    ForEach(viewModel.trailingSections.filter { $0.id != "clips" }) { section in
                        StorefrontSectionView(
                            section: section,
                            isHomeTab: false,
                            cohort: viewModel.selectedProfile?.quickplayCohort ?? .entertainment,
                            heroVariant: .carousel,
                            onViewAll: nil,
                            onSelectItem: onSelectItem
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
        }
    }

    private var downloadsCard: some View {
        Button(action: {}) {
            HStack(spacing: UIConstants.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.sm, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    Image(systemName: AppIcons.Action.download)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(AppStrings.Profile.downloads)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(AppStrings.Profile.downloadsSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.5))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: AppIcons.Navigation.next)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.76))
            }
            .padding(UIConstants.Spacing.lg)
            .background(
                LiquidGlassBackground(cornerRadius: 14, tone: .dark)
            )
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private var upgradeCard: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.lg) {
            HStack(alignment: .top) {
                Text(AppStrings.Profile.upgradePlan)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                Spacer()
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.md, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "B87044"), Color(hex: "5D2D1B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(45))
                    .offset(x: 18, y: -12)
            }

            VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
                featurePill("Upto 5 devices")
                featurePill("High Audio & Video Quality")
                featurePill("Regional daily shows")
                featurePill("Ads Free Movies and shows")
            }

            Button(action: {}) {
                HStack {
                    Spacer()
                    Text(AppStrings.Profile.premiumCTA)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: AppIcons.Navigation.next)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(height: 46)
                .background(LiquidGlassBackground(cornerRadius: UIConstants.CornerRadius.lg, tone: .accent, isHighlighted: true))
            }
            .buttonStyle(LiquidButtonPressStyle())

            Text(AppStrings.Profile.subscribeLater)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.38))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(UIConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "131022"), Color(hex: "2B120F")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: "7B4F2D"), lineWidth: 1)
                )
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

    private func roundedIconButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(LiquidGlassBackground(cornerRadius: 16, tone: .dark))
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private func featurePill(_ title: String) -> some View {
        HStack(spacing: UIConstants.Spacing.sm) {
            Image(systemName: "checkmark.seal")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(hex: "F4C15D"))
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.82))
        }
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
}

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
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea()
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
            let baseHeaderHeight = 248 + topInset
            let scrollMinY = proxy.frame(in: .named("profileHubScroll")).minY
            let pullDistance = max(scrollMinY, 0)
            let scrollDistance = max(-scrollMinY, 0)
            let imageHeight = baseHeaderHeight + pullDistance
            let imageOffset = scrollMinY > 0 ? -pullDistance : -scrollDistance * 0.34

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Image("proBg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: screenWidth, height: imageHeight)
                        .scaleEffect(1 + min(pullDistance / 900, 0.08), anchor: .top)
                        .offset(y: imageOffset)
                        .clipped()

                    LinearGradient(
                        colors: [Color.black.opacity(0.12), Color.black.opacity(0.18), Color.black.opacity(0.86)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: screenWidth, height: imageHeight)
                    .offset(y: scrollMinY > 0 ? -pullDistance : imageOffset)

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
                                        .font(.system(size: 14, weight: .semibold))
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
                        .padding(.bottom, 14)
                    }
                }
                .frame(height: baseHeaderHeight)
                .clipped()
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
            Image("upgradebg")
                .resizable()
                .scaledToFit()
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(LiquidButtonPressStyle())
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

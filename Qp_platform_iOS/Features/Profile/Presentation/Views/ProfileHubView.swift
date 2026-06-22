import SwiftUI

struct ProfileHubView: View {
    @ObservedObject var viewModel: ProfileHubViewModel
    let onBack: () -> Void
    let onOpenSettings: () -> Void
    let onSwitchProfile: () -> Void
    let onSelectItem: (StorefrontItem) -> Void

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                header(topInset: proxy.safeAreaInsets.top)

                content
            }
            .ignoresSafeArea(edges: .top)
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private func header(topInset: CGFloat) -> some View {
        GeometryReader { proxy in
            let screenWidth = max(proxy.size.width, 320)
            let headerHeight = 234 + topInset

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    if let heroItem = viewModel.heroItem {
                        PosterImageView(
                            url: heroItem.imageURL(for: "0-16x9", width: Int(screenWidth * 3)),
                            size: CGSize(width: screenWidth, height: headerHeight),
                            cornerRadius: 0
                        )
                    } else {
                        LinearGradient(
                            colors: [Color(hex: "351236"), Color(hex: "0E0A14")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: headerHeight)
                    }

                    LinearGradient(
                        colors: [Color.black.opacity(0.08), Color.black.opacity(0.18), Color.black.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: headerHeight)

                    HStack {
                        roundedIconButton(icon: AppIcons.Navigation.back, action: onBack)
                        Spacer()
                        roundedIconButton(icon: AppIcons.Action.download, action: {})
                        roundedIconButton(icon: AppIcons.Action.gear, action: onOpenSettings)
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                    .padding(.top, topInset + 8)
                }
                .frame(height: headerHeight)

                Button(action: onSwitchProfile) {
                    ZStack {
                        HStack {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white.opacity(0.88))
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            Text(viewModel.displayedProfileName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.82))
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 234 + topInset + 51)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.sections.isEmpty {
            LoadingView()
        } else if let errorMessage = viewModel.errorMessage, viewModel.sections.isEmpty {
            ErrorView(title: AppStrings.Profile.yourProfiles, message: errorMessage, onRetry: {
                Task { await viewModel.loadIfNeeded() }
            })
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: UIConstants.Spacing.xl) {
                    if let leadingSection = viewModel.leadingSection {
                        profileRailSection(leadingSection, style: .poster, width: 188)
                    }

                    downloadsCard
                        .padding(.horizontal, UIConstants.Spacing.lg)

                    if let clipsSection = viewModel.sections.first(where: { $0.id == "clips" }) {
                        profileRailSection(clipsSection, style: .short, width: 188)
                    }

                    ForEach(viewModel.trailingSections.filter { $0.id != "clips" }) { section in
                        StorefrontSectionView(section: section, isHomeTab: false, cohort: viewModel.selectedProfile?.quickplayCohort ?? .entertainment, onViewAll: nil, onSelectItem: onSelectItem)
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF9D3E"), Color(hex: "FF5A00")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)

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
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)

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
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.26))
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "B67014").opacity(0.9), lineWidth: 1.1)
                        )
                )
        }
        .buttonStyle(.plain)
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

import SwiftUI

struct ProfileHubView: View {
    @ObservedObject var viewModel: ProfileHubViewModel
    let onBack: () -> Void
    let onOpenSettings: () -> Void
    let onSwitchProfile: () -> Void
    let onSelectItem: (StorefrontItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            content
        }
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var header: some View {
        GeometryReader { proxy in
            let screenWidth = max(proxy.size.width, 320)

            ZStack(alignment: .top) {
                if let heroItem = viewModel.heroItem {
                    PosterImageView(
                        url: heroItem.imageURL(for: "0-16x9", width: Int(screenWidth * 3)),
                        size: CGSize(width: screenWidth, height: 210),
                        cornerRadius: 0
                    )
                } else {
                    LinearGradient(
                        colors: [Color(hex: "351236"), Color(hex: "0E0A14")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 210)
                }

                LinearGradient(
                    colors: [Color.black.opacity(0.16), Color.black.opacity(0.46), Color.black.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 210)

                VStack(spacing: UIConstants.Spacing.lg) {
                    StatusBarView()
                        .padding(.horizontal, UIConstants.Spacing.xl)
                        .padding(.top, UIConstants.Spacing.sm + 2)

                    HStack {
                        roundedIconButton(icon: AppIcons.Navigation.back, action: onBack)
                        Spacer()
                        roundedIconButton(icon: AppIcons.Action.download, action: {})
                        roundedIconButton(icon: AppIcons.Action.gear, action: onOpenSettings)
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)

                    Spacer()

                    Button(action: onSwitchProfile) {
                        HStack(spacing: UIConstants.Spacing.md) {
                            ProfileAvatarView(
                                imageName: viewModel.displayedProfileImageName,
                                fallbackGlyph: String(viewModel.displayedProfileName.prefix(1)).uppercased(),
                                size: 54
                            )

                            Text(viewModel.displayedProfileName)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)

                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.white.opacity(0.72))

                            Spacer()
                        }
                        .padding(.horizontal, UIConstants.Spacing.lg)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, UIConstants.Spacing.lg)
                }
            }
        }
        .frame(height: 210)
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
                        StorefrontSectionView(section: leadingSection, isHomeTab: false, onSelectItem: onSelectItem)
                    }

                    downloadsCard
                        .padding(.horizontal, UIConstants.Spacing.lg)

                    ForEach(viewModel.trailingSections) { section in
                        StorefrontSectionView(section: section, isHomeTab: false, onSelectItem: onSelectItem)
                    }

                    if !AppEnvironment.AuthSession.hasActiveSubscription {
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
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous)
                    .fill(Color.white.opacity(0.06))
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
                    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.lg, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
}

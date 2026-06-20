import SwiftUI

struct StorefrontHeaderView: View {
    let tabs: [StorefrontTab]
    let selectedTabID: String?
    let profileName: String
    let onSelectTab: (StorefrontTab) -> Void
    let onProfileTap: () -> Void

    var body: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            StatusBarView()
                .padding(.horizontal, UIConstants.Spacing.xl)
                .padding(.top, UIConstants.Spacing.sm + 2)

            HStack(spacing: UIConstants.Spacing.lg) {
                HStack(spacing: UIConstants.Spacing.md) {
                    Image("minilogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 30)

                    Button(action: {}) {
                        HStack(spacing: UIConstants.Spacing.xs + 2) {
                            Image(systemName: AppIcons.Action.sparkles)
                                .font(.caption.weight(.bold))
                            Text(AppStrings.Storefront.subscribe)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color(hex: "E2C06D"))
                        .padding(.horizontal, UIConstants.Spacing.md - 2)
                        .frame(height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.sm, style: .continuous)
                                .stroke(Color(hex: "7D6735"), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                HStack(spacing: UIConstants.Spacing.lg) {
                    Image(systemName: AppIcons.Action.bell)
                    Image(systemName: AppIcons.Action.tv)
                    Button(action: onProfileTap) {
                        ProfileAvatarView(imageName: ProfileArtworkResolver.imageName(forName: profileName), fallbackGlyph: "P", size: UIConstants.Size.avatarSmall)
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
            }
            .padding(.horizontal, UIConstants.Spacing.lg)

            if !tabs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: UIConstants.Spacing.sm + 2) {
                        ForEach(tabs) { tab in
                            Button {
                                onSelectTab(tab)
                            } label: {
                                Text(tab.title)
                                    .font(.subheadline.weight(selectedTabID == tab.id ? .bold : .medium))
                                    .foregroundStyle(selectedTabID == tab.id ? .black : .white.opacity(0.82))
                                    .padding(.horizontal, 14)
                                    .frame(height: 30)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(selectedTabID == tab.id ? Color(hex: "F1B944") : Color.white.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.lg)
                }
            }
        }
    }
}

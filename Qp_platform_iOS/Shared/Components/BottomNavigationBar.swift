import SwiftUI

enum BottomNavigationSelection {
    case home
    case search
    case hot
}

struct BottomNavigationBar: View {
    let selection: BottomNavigationSelection
    let profileImageName: String?
    let onHomeTap: () -> Void
    let onSearchTap: () -> Void
    let onHotTap: () -> Void
    let onProfileTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.white.opacity(0.08))

            HStack(spacing: 0) {
                navButton(icon: AppIcons.Navigation.home, label: AppStrings.Common.home, isSelected: selection == .home, action: onHomeTap)
                navButton(icon: AppIcons.Navigation.search, label: AppStrings.Common.search, isSelected: selection == .search, action: onSearchTap)
                navItem(icon: AppIcons.Navigation.library, label: AppStrings.Common.library, isSelected: false)
                navButton(icon: AppIcons.Navigation.hot, label: AppStrings.Common.hot, isSelected: selection == .hot, action: onHotTap)

                Button(action: onProfileTap) {
                    VStack(spacing: UIConstants.Spacing.xs + 2) {
                        if let profileImageName {
                            ProfileAvatarView(imageName: profileImageName, fallbackGlyph: "P", size: UIConstants.Size.avatarSmall)
                        } else {
                            Image(systemName: AppIcons.Navigation.profile)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.76))
                        }

                        Text(AppStrings.Common.mySpace)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, UIConstants.Spacing.md - 2)
                    .padding(.bottom, UIConstants.Spacing.sm)
                }
                .buttonStyle(.plain)
            }
            .background(Color.black.opacity(0.96))
        }
    }

    private func navButton(icon: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            navItem(icon: icon, label: label, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func navItem(icon: String, label: String, isSelected: Bool) -> some View {
        VStack(spacing: UIConstants.Spacing.xs + 2) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isSelected ? Color(hex: "F1B944") : Color.white.opacity(0.76))

            Text(label)
                .font(.caption2.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color(hex: "F1B944") : Color.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, UIConstants.Spacing.md - 2)
        .padding(.bottom, UIConstants.Spacing.sm)
    }
}

#Preview {
    BottomNavigationBar(selection: .home, profileImageName: nil, onHomeTap: {}, onSearchTap: {}, onHotTap: {}, onProfileTap: {})
}

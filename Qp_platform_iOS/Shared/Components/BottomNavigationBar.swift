import SwiftUI

enum BottomNavigationSelection {
    case home
    case search
    case shorts
    case hot
}

struct BottomNavigationBar: View {
    let selection: BottomNavigationSelection
    let profileImageName: String?
    let onHomeTap: () -> Void
    let onSearchTap: () -> Void
    let onShortsTap: () -> Void
    let onHotTap: () -> Void
    let onProfileTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            navButton(icon: AppIcons.Navigation.home, label: AppStrings.Common.home, isSelected: selection == .home, action: onHomeTap)
            navButton(icon: AppIcons.Navigation.search, label: AppStrings.Common.search, isSelected: selection == .search, action: onSearchTap)
            navButton(icon: AppIcons.Navigation.library, label: AppStrings.Common.library, isSelected: selection == .shorts, action: onShortsTap)
            navButton(icon: AppIcons.Navigation.hot, label: AppStrings.Common.hot, isSelected: selection == .hot, action: onHotTap)
            profileButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 300, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color(hex: "FF8100").opacity(0.05),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 300, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 9)
    }

    private func navButton(icon: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            navItem(icon: icon, label: label, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func navItem(icon: String, label: String, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isSelected ? Color(hex: "DAB316") : Color(hex: "B4B4B4"))
                .frame(width: 24, height: 24)

            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .tracking(0.48)
                .foregroundStyle(isSelected ? Color(hex: "DAB316") : Color(hex: "B4B4B4"))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46, alignment: .top)
        .overlay(alignment: .bottom) {
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "DAB316").opacity(0.5))
                    .frame(width: 33, height: 16)
                    .blur(radius: 6)
                    .offset(y: 8)
            }
        }
    }

    private var profileButton: some View {
        Button(action: onProfileTap) {
            VStack(spacing: 6) {
                if let profileImageName {
                    ProfileAvatarView(imageName: profileImageName, fallbackGlyph: "P", size: 24)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: AppIcons.Navigation.profile)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color(hex: "B4B4B4"))
                        .frame(width: 24, height: 24)
                }

                Text(AppStrings.Common.mySpace)
                    .font(.system(size: 12, weight: .regular))
                    .tracking(0.48)
                    .foregroundStyle(Color(hex: "B4B4B4"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46, alignment: .top)
            .opacity(0.9)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    BottomNavigationBar(selection: .home, profileImageName: nil, onHomeTap: {}, onSearchTap: {}, onShortsTap: {}, onHotTap: {}, onProfileTap: {})
}

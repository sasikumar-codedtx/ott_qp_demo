import SwiftUI

enum BottomNavigationSelection {
    case home
    case search
    case shorts
    case hot
}

struct BottomNavigationBar: View {
    private enum TabbarAsset {
        static let home = "home"
        static let search = "search"
        static let shorts = "shorts"
        static let fire = "fire"
    }

    let selection: BottomNavigationSelection
    let profileImageName: String?
    let onHomeTap: () -> Void
    let onSearchTap: () -> Void
    let onShortsTap: () -> Void
    let onHotTap: () -> Void
    let onProfileTap: () -> Void

    var body: some View {
        barContent
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 9)
            .frame(height: 61)
            .frame(maxWidth: 380)
            .background(barBackground)
            .shadow(color: Color.black.opacity(0.42), radius: 18, x: 0, y: 8)
            .padding(.horizontal, 16)
    }

    private var barContent: some View {
        HStack(alignment: .top, spacing: 0) {
            navButton(assetName: TabbarAsset.home, label: AppStrings.Common.home, isSelected: selection == .home, action: onHomeTap)
            navButton(assetName: TabbarAsset.search, label: AppStrings.Common.search, isSelected: selection == .search, action: onSearchTap)
            navButton(assetName: TabbarAsset.shorts, label: AppStrings.Common.library, isSelected: selection == .shorts, action: onShortsTap)
            navButton(assetName: TabbarAsset.fire, label: AppStrings.Common.hot, isSelected: selection == .hot, action: onHotTap)
            profileButton
        }
    }

    private var barBackground: some View {
        BottomNavigationGlassBackground()
    }

    private func navButton(assetName: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            navItem(assetName: assetName, label: label, isSelected: isSelected)
        }
        .buttonStyle(LiquidButtonPressStyle())
        .frame(maxWidth: .infinity)
    }

    private func navItem(assetName: String, label: String, isSelected: Bool) -> some View {
        ZStack(alignment: .top) {
            if isSelected {
                Rectangle()
                    .fill(selectedColor)
                    .frame(width: 33, height: 16)
                    .blur(radius: 6)
                    .opacity(0.5)
                    .offset(y: 36)
            }

            VStack(spacing: 6) {
                Image(assetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(isSelected ? selectedColor : inactiveColor)
                    .frame(width: 24, height: 24)

                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .tracking(0.48)
                    .foregroundStyle(isSelected ? selectedColor : inactiveColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .frame(height: 12)
            }
        }
        .frame(width: 48)
        .frame(height: 49, alignment: .top)
    }

    private var profileButton: some View {
        Button(action: onProfileTap) {
            VStack(spacing: 6) {
                if let profileImageName {
                    ProfileAvatarView(imageName: profileImageName, fallbackGlyph: "P", size: 24)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: AppIcons.Navigation.profile)
                        .font(.system(size: 23, weight: .regular))
                        .foregroundStyle(inactiveColor)
                        .frame(width: 24, height: 24)
                }

                Text(AppStrings.Common.mySpace)
                    .font(.system(size: 12, weight: .regular))
                    .tracking(0.48)
                    .foregroundStyle(inactiveColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(height: 12)
            }
            .frame(width: 48)
            .frame(height: 49, alignment: .top)
            .opacity(0.9)
        }
        .buttonStyle(LiquidButtonPressStyle())
        .frame(maxWidth: .infinity)
    }

    private var selectedColor: Color {
        Color(hex: "DAB316")
    }

    private var inactiveColor: Color {
        Color(hex: "B4B4B4")
    }
}

private struct BottomNavigationGlassBackground: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(softOrangeSheen)
            .overlay(Color.black.opacity(0.6).clipShape(Capsule(style: .continuous)))
            .overlay(border)
            .background(shadowFill)
    }

    private var softOrangeSheen: some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color(hex: "FF8100").opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var border: some View {
        Capsule(style: .continuous)
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
    }

    private var shadowFill: some View {
        Capsule(style: .continuous)
            .fill(Color.black.opacity(0.64))
            .blur(radius: 12)
    }
}

#Preview {
    BottomNavigationBar(selection: .home, profileImageName: nil, onHomeTap: {}, onSearchTap: {}, onShortsTap: {}, onHotTap: {}, onProfileTap: {})
}

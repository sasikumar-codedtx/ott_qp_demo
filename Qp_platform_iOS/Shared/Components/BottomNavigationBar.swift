import SwiftUI

enum BottomNavigationSelection {
    case home
    case search
    case shorts
    case hot
}

struct BottomNavigationBar: View {
    private enum Metrics {
        static let idealWidth: CGFloat = 380
        static let horizontalInset: CGFloat = 16
        static let height: CGFloat = 61
        static let rowHeight: CGFloat = 42
        static let itemWidth: CGFloat = 48
        static let iconSize: CGFloat = 24
        static let selectedGlowWidth: CGFloat = 33
        static let selectedGlowHeight: CGFloat = 16
    }

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
        HStack(alignment: .top, spacing: 0) {
            navButton(assetName: TabbarAsset.home, label: AppStrings.Common.home, isSelected: selection == .home, action: onHomeTap)
            Spacer(minLength: 0)
            navButton(assetName: TabbarAsset.search, label: AppStrings.Common.search, isSelected: selection == .search, action: onSearchTap)
            Spacer(minLength: 0)
            navButton(assetName: TabbarAsset.shorts, label: AppStrings.Common.library, isSelected: selection == .shorts, action: onShortsTap)
            Spacer(minLength: 0)
            navButton(assetName: TabbarAsset.fire, label: AppStrings.Common.hot, isSelected: selection == .hot, action: onHotTap)
            Spacer(minLength: 0)
            profileButton
        }
        .frame(height: Metrics.rowHeight)
        .padding(.horizontal, Metrics.horizontalInset)
        .padding(.top, 10)
        .padding(.bottom, 9)
        .frame(maxWidth: Metrics.idealWidth)
        .background(barBackground)
        .frame(maxWidth: .infinity)
    }

    private var barBackground: some View {
        BottomNavigationSurface()
    }

    private func navButton(assetName: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            navItem(assetName: assetName, label: label, isSelected: isSelected)
        }
        .contentShape(Rectangle())
        .buttonStyle(LiquidButtonPressStyle())
        .frame(width: Metrics.itemWidth, height: Metrics.rowHeight)
    }

    private func navItem(assetName: String, label: String, isSelected: Bool) -> some View {
        ZStack(alignment: .top) {
            selectedIndicator(isSelected: isSelected)
                .offset(y: 36)

            VStack(spacing: 6) {
                Image(assetName)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    .opacity(isSelected ? 1.0 : 0.55)

                Text(label)
                    .font(.system(size: 12, weight: .regular))
                    .tracking(0.48)
                    .foregroundStyle(isSelected ? selectedColor : inactiveColor)
                    .lineLimit(1)
                    .frame(height: 12)
            }
        }
        .frame(width: Metrics.itemWidth, height: Metrics.rowHeight, alignment: .top)
        .contentShape(Rectangle())
    }

    private var profileButton: some View {
        Button(action: onProfileTap) {
            ZStack(alignment: .top) {
                VStack(spacing: 6) {
                    if let profileImageName {
                        ProfileAvatarView(imageName: profileImageName, fallbackGlyph: "P", size: Metrics.iconSize)
                            .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        Image(systemName: AppIcons.Navigation.profile)
                            .font(.system(size: 23, weight: .medium))
                            .foregroundStyle(inactiveColor)
                            .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    }

                    Text(AppStrings.Common.mySpace)
                        .font(.system(size: 12, weight: .regular))
                        .tracking(0.48)
                        .foregroundStyle(inactiveColor)
                        .lineLimit(1)
                        .frame(height: 12)
                }
            }
            .frame(width: Metrics.itemWidth, height: Metrics.rowHeight, alignment: .top)
            .contentShape(Rectangle())
            .opacity(0.95)
        }
        .contentShape(Rectangle())
        .buttonStyle(LiquidButtonPressStyle())
        .frame(width: Metrics.itemWidth, height: Metrics.rowHeight)
    }

    private func selectedIndicator(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hex: "DAB316"))
            .frame(width: Metrics.selectedGlowWidth, height: Metrics.selectedGlowHeight)
            .blur(radius: 6)
            .opacity(isSelected ? 0.5 : 0)
            .accessibilityHidden(true)
    }

    private var selectedColor: Color {
        Color(hex: "DAB316")
    }

    private var inactiveColor: Color {
        Color(hex: "B4B4B4")
    }
}

private struct BottomNavigationSurface: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.6))
            )
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.05), location: 0),
                        .init(color: Color(hex: "FF8100").opacity(0.05), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(Capsule(style: .continuous))
            )
            .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

#Preview {
    BottomNavigationBar(selection: .home, profileImageName: nil, onHomeTap: {}, onSearchTap: {}, onShortsTap: {}, onHotTap: {}, onProfileTap: {})
}

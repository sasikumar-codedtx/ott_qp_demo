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
        static let height: CGFloat = 58
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
        GeometryReader { proxy in
            let chromeWidth = max(0, min(Metrics.idealWidth, proxy.size.width - 32))
            let rowWidth = max(0, chromeWidth - (Metrics.horizontalInset * 2))

            barContent(rowWidth: rowWidth)
                .frame(width: rowWidth, height: Metrics.rowHeight)
                .padding(.horizontal, Metrics.horizontalInset)
                .padding(.top, 8)
                .frame(width: chromeWidth, height: Metrics.height, alignment: .top)
                .background(barBackground)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: Metrics.height)
    }

    private func barContent(rowWidth: CGFloat) -> some View {
        let spacing = max(12, (rowWidth - (Metrics.itemWidth * 5)) / 4)

        return HStack(alignment: .top, spacing: spacing) {
            navButton(assetName: TabbarAsset.home, label: AppStrings.Common.home, isSelected: selection == .home, action: onHomeTap)
            navButton(assetName: TabbarAsset.search, label: AppStrings.Common.search, isSelected: selection == .search, action: onSearchTap)
            navButton(assetName: TabbarAsset.shorts, label: AppStrings.Common.library, isSelected: selection == .shorts, action: onShortsTap)
            navButton(assetName: TabbarAsset.fire, label: AppStrings.Common.hot, isSelected: selection == .hot, action: onHotTap)
            profileButton
        }
        .frame(width: rowWidth, height: Metrics.rowHeight, alignment: .top)
    }

    private var barBackground: some View {
        BottomNavigationSurface()
    }

    private func navButton(assetName: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            navItem(assetName: assetName, label: label, isSelected: isSelected)
        }
        .buttonStyle(LiquidButtonPressStyle())
        .frame(width: Metrics.itemWidth, height: Metrics.rowHeight)
    }

    private func navItem(assetName: String, label: String, isSelected: Bool) -> some View {
        ZStack(alignment: .top) {
            selectedIndicator(isSelected: isSelected)
                .offset(y: 32)

            VStack(spacing: 6) {
                Image(assetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(isSelected ? selectedColor : inactiveColor)
                    .frame(width: Metrics.iconSize, height: Metrics.iconSize)

                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? selectedColor : inactiveColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                    .frame(width: labelWidth(for: label), height: 12)
            }
        }
        .frame(width: Metrics.itemWidth, height: Metrics.rowHeight, alignment: .top)
    }

    private var profileButton: some View {
        Button(action: onProfileTap) {
            ZStack(alignment: .top) {
                VStack(spacing: 6) {
                    if let profileImageName {
                        ProfileAvatarView(imageName: profileImageName, fallbackGlyph: "P", size: Metrics.iconSize)
                            .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    } else {
                        Image(systemName: AppIcons.Navigation.profile)
                            .font(.system(size: 23, weight: .medium))
                            .foregroundStyle(inactiveColor)
                            .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                    }

                    Text(AppStrings.Common.mySpace)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(inactiveColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                        .frame(width: labelWidth(for: AppStrings.Common.mySpace), height: 12)
                }
            }
            .frame(width: Metrics.itemWidth, height: Metrics.rowHeight, alignment: .top)
            .opacity(0.95)
        }
        .buttonStyle(.plain)
        .frame(width: Metrics.itemWidth, height: Metrics.rowHeight)
    }

    private func selectedIndicator(isSelected: Bool) -> some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "F7C638").opacity(0.95),
                            Color(hex: "FF7A00").opacity(0.42),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: Metrics.selectedGlowWidth, height: Metrics.selectedGlowHeight)
                .blur(radius: 4)

            Capsule(style: .continuous)
                .fill(Color(hex: "F6D45A"))
                .frame(width: 18, height: 2)
                .offset(y: 5)
        }
        .opacity(isSelected ? 1 : 0)
        .accessibilityHidden(true)
    }

    private func labelWidth(for label: String) -> CGFloat {
        switch label {
        case AppStrings.Common.hot:
            return 62
        case AppStrings.Common.mySpace:
            return 58
        default:
            return 48
        }
    }

    private var selectedColor: Color {
        Color(hex: "F3D53F")
    }

    private var inactiveColor: Color {
        Color(hex: "B7B7B7")
    }
}

private struct BottomNavigationSurface: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(Color(hex: "3A3A3A").opacity(0.78))
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.06),
                        Color.black.opacity(0.28)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(Capsule(style: .continuous))
            )
            .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.22), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.34), radius: 12, x: 0, y: 5)
    }
}

#Preview {
    BottomNavigationBar(selection: .home, profileImageName: nil, onHomeTap: {}, onSearchTap: {}, onShortsTap: {}, onHotTap: {}, onProfileTap: {})
}

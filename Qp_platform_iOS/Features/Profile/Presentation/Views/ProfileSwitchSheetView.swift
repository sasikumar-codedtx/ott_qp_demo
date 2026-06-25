import SwiftUI

struct ProfileSwitchSheetView: View {
    let profiles: [Profile]
    let selectedProfile: Profile?
    let onSelect: (Profile) -> Void
    let onAddProfile: () -> Void
    let onEditProfiles: () -> Void
    let onClose: (() -> Void)?

    private let avatarSize: CGFloat = 89.636
    private let avatarGap: CGFloat = 32
    private let panelHeight: CGFloat = 609
    private let logoSize: CGFloat = 82
    private let maxProfiles = 5

    private enum SwitchTile: Identifiable {
        case profile(Profile)
        case add

        var id: String {
            switch self {
            case .profile(let profile):
                return profile.id.uuidString
            case .add:
                return "add-profile"
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let panelWidth = proxy.size.width
            let totalHeight = min(panelHeight, proxy.size.height * 0.82)

            ZStack(alignment: .bottom) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onClose?()
                    }

                sheetContent(width: panelWidth, height: totalHeight)
                    .frame(width: panelWidth, height: totalHeight)
                    .contentShape(Rectangle())
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func sheetContent(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            background(width: width, height: height)
                .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: logoSize * 0.52)

                Text(AppStrings.Profile.switchProfile)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 18)

                Text(AppStrings.Profile.switchProfileSubtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.42))
                    .padding(.top, 8)

                profileRows
                    .padding(.top, 48)

                Spacer(minLength: 18)

                Button(action: onEditProfiles) {
                    HStack(spacing: 6) {
                        Text(AppStrings.Profile.editProfilesCTA)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)

                        Image(systemName: "pencil.line")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 16, height: 16)
                    }
                    .frame(height: 22)
                }
                .buttonStyle(LiquidButtonPressStyle())
                .padding(.bottom, 48)
            }
            .frame(width: width, height: height)

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
                .offset(y: -(logoSize * 0.5))
        }
        .frame(width: width, height: height)
        .accessibilityElement(children: .contain)
    }

    private func background(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            Image("sliceBg")
                .resizable()
                .scaledToFill()
                .frame(width: width + 2, height: height + 2)
                .clipped()

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.88),
                            Color.black.opacity(0.72),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: width * 0.58
                    )
                )
                .frame(width: width * 1.42, height: height * 0.46)
                .offset(y: height * 0.12)

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.04),
                    Color.black.opacity(0.58),
                    Color.black.opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: width, height: height)
        .background(Color.clear)
        .clipped()
    }

    private var profileRows: some View {
        let visibleProfiles = Array(profiles.prefix(maxProfiles))
        let profileTiles = visibleProfiles.map(SwitchTile.profile)
        let tiles = visibleProfiles.count < maxProfiles ? profileTiles + [.add] : profileTiles
        let topRow = Array(tiles.prefix(3))
        let bottomRow = Array(tiles.dropFirst(3).prefix(3))

        return VStack(spacing: 32) {
            HStack(spacing: avatarGap) {
                ForEach(topRow) { tile in
                    tileView(tile)
                }
            }

            if !bottomRow.isEmpty {
                HStack(spacing: avatarGap) {
                    ForEach(bottomRow) { tile in
                        tileView(tile)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tileView(_ tile: SwitchTile) -> some View {
        switch tile {
        case .profile(let profile):
            profileButton(profile)
        case .add:
            addProfileButton
        }
    }

    private func profileButton(_ profile: Profile) -> some View {
        let isSelected = profile.id == selectedProfile?.id

        return Button {
            onSelect(profile)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    ProfileAvatarView(
                        imageName: profile.imageName,
                        fallbackGlyph: profile.fallbackGlyph,
                        size: avatarSize
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 19.208, style: .continuous))

                    if isSelected {
                        RoundedRectangle(cornerRadius: 19.208, style: .continuous)
                            .fill(Color.black.opacity(0.34))
                            .frame(width: avatarSize, height: avatarSize)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 19.208, style: .continuous)
                        .stroke(Color.white.opacity(isSelected ? 0.92 : 0), lineWidth: 3)
                        .padding(isSelected ? -6 : 0)
                )
                .shadow(
                    color: isSelected ? Color(hex: "F4B000").opacity(0.32) : .clear,
                    radius: 18,
                    x: 0,
                    y: 10
                )

                Text(profile.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(width: avatarSize)
            }
            .frame(width: avatarSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private var addProfileButton: some View {
        Button(action: onAddProfile) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 19.208, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 19.208, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                Text(AppStrings.Profile.addProfile)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(width: avatarSize)
            }
            .frame(width: avatarSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(LiquidButtonPressStyle())
    }
}

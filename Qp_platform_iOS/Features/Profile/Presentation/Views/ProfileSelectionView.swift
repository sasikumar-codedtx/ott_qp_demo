import SwiftUI

struct ProfileSelectionView: View {
    @ObservedObject var viewModel: ProfileSelectionViewModel
    let onSelect: (Profile) -> Void
    let onAddProfile: () -> Void
    let onEditProfiles: () -> Void

    @State private var selectedProfileID: UUID?
    @State private var isExitingToStorefront = false

    private let designWidth: CGFloat = 412
    private let designHeight: CGFloat = 917
    private let avatarSize: CGFloat = 89.636
    private let avatarGap: CGFloat = 32

    private enum SelectionTile: Identifiable {
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
            let fullWidth = proxy.size.width
            let fullHeight = proxy.size.height
            let scale = min(fullWidth / designWidth, fullHeight / designHeight, 1)
            let canvasWidth = min(designWidth * scale, fullWidth)
            let canvasHeight = min(designHeight * scale, fullHeight)

            ZStack {
                background(width: fullWidth, height: fullHeight)

                ZStack {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 93.753 * scale, height: 93.471 * scale)
                        .position(x: fullWidth / 2, y: 150 * scale)

                    profileBlock(scale: scale, canvasWidth: canvasWidth)
                        .position(x: fullWidth / 2, y: 640 * scale)

                    editProfilesButton(scale: scale)
                        .position(x: fullWidth / 2, y: 861 * scale)
                }
                .frame(width: fullWidth, height: canvasHeight)
                .opacity(isExitingToStorefront ? 0.28 : 1)
                .scaleEffect(isExitingToStorefront ? 1.025 : 1)
                .animation(.easeInOut(duration: 0.26), value: isExitingToStorefront)

                if viewModel.isLoading {
                    LoadingView()
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(title: AppStrings.Profile.yourProfiles, message: errorMessage, onRetry: {
                        Task { await viewModel.load() }
                    })
                    .padding(.horizontal, 24)
                }
            }
            .frame(width: fullWidth, height: fullHeight)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .ignoresSafeArea()
        .task {
            if viewModel.profiles.isEmpty {
                await viewModel.load()
            }
        }
    }

    private func background(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Image("sliceBg")
                .resizable()
                .scaledToFill()
                // The exported Figma slice has gray edge pixels baked into both sides.
                // Overscanning crops those pixels so the artwork truly reaches the screen edge.
                .frame(width: width * 1.08, height: height * 1.08)
        }
        .frame(width: width, height: height)
        .clipped()
    }

    private func profileBlock(scale: CGFloat, canvasWidth: CGFloat) -> some View {
        VStack(spacing: 60 * scale) {
            Text("Who’s Watching")
                .font(.system(size: 24 * scale, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 332.907 * scale)
                .lineLimit(1)

            profileRows(scale: scale)
        }
        .frame(width: 332.907 * scale)
    }

    private func profileRows(scale: CGFloat) -> some View {
        let profileTiles = viewModel.selectionProfiles.prefix(5).map(SelectionTile.profile)
        let tiles = viewModel.canAddProfile ? profileTiles + [.add] : profileTiles
        let topRow = Array(tiles.prefix(3))
        let bottomRow = Array(tiles.dropFirst(3).prefix(3))

        return VStack(spacing: 32 * scale) {
            HStack(spacing: avatarGap * scale) {
                ForEach(topRow) { tile in
                    tileView(tile, scale: scale)
                }
            }
            .frame(width: 332.907 * scale)

            HStack(spacing: avatarGap * scale) {
                ForEach(bottomRow) { tile in
                    tileView(tile, scale: scale)
                }
            }
        }
    }

    @ViewBuilder
    private func tileView(_ tile: SelectionTile, scale: CGFloat) -> some View {
        switch tile {
        case .profile(let profile):
            profileButton(profile, scale: scale)
        case .add:
            addProfileButton(scale: scale)
        }
    }

    private func profileButton(_ profile: Profile, scale: CGFloat) -> some View {
        Button {
            selectProfileWithAnimation(profile)
        } label: {
            VStack(spacing: 8 * scale) {
                ProfileAvatarView(
                    imageName: profile.imageName,
                    fallbackGlyph: profile.fallbackGlyph,
                    size: avatarSize * scale
                )
                .clipShape(RoundedRectangle(cornerRadius: 19.208 * scale, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 19.208 * scale, style: .continuous)
                        .stroke(profile.id == selectedProfileID ? Color.white.opacity(0.92) : .clear, lineWidth: 2.2 * scale)
                        .padding(-4 * scale)
                )
                .shadow(
                    color: profile.id == selectedProfileID ? Color(hex: "F4B000").opacity(0.35) : .clear,
                    radius: 16 * scale,
                    x: 0,
                    y: 8 * scale
                )

                Text(profile.name)
                    .font(.system(size: 12 * scale, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: avatarSize * scale)
            }
            .frame(width: avatarSize * scale)
            .scaleEffect(profile.id == selectedProfileID ? 1.1 : 1)
            .opacity(isExitingToStorefront && profile.id != selectedProfileID ? 0.34 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: selectedProfileID)
            .animation(.easeInOut(duration: 0.22), value: isExitingToStorefront)
        }
        .buttonStyle(LiquidButtonPressStyle())
        .disabled(isExitingToStorefront)
    }

    private func addProfileButton(scale: CGFloat) -> some View {
        Button(action: onAddProfile) {
            VStack(spacing: 8 * scale) {
                RoundedRectangle(cornerRadius: 19.208 * scale, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: avatarSize * scale, height: avatarSize * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 19.208 * scale, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 32 * scale, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                Text(AppStrings.Profile.addProfile)
                    .font(.system(size: 12 * scale, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: avatarSize * scale)
            }
            .frame(width: avatarSize * scale)
        }
        .buttonStyle(LiquidButtonPressStyle())
        .disabled(isExitingToStorefront)
    }

    private func editProfilesButton(scale: CGFloat) -> some View {
        Button(action: onEditProfiles) {
            HStack(spacing: 6 * scale) {
                Text(AppStrings.Profile.editProfilesCTA)
                    .font(.system(size: 14 * scale, weight: .semibold))
                    .foregroundStyle(.white)

                Image(systemName: "pencil.line")
                    .font(.system(size: 14 * scale, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 16 * scale, height: 16 * scale)
            }
            .frame(height: 20 * scale)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private func selectProfileWithAnimation(_ profile: Profile) {
        guard !isExitingToStorefront else { return }
        selectedProfileID = profile.id

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.82)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.62)) {
            isExitingToStorefront = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            onSelect(profile)
            selectedProfileID = nil
            isExitingToStorefront = false
        }
    }
}

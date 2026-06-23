import SwiftUI

struct ProfileSwitchSheetView: View {
    let profiles: [Profile]
    let selectedProfile: Profile?
    let onSelect: (Profile) -> Void
    let onEditProfiles: () -> Void
    let onClose: (() -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 18) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 46, height: 4)
                    .padding(.top, 8)

                header

                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(profiles.prefix(6)) { profile in
                        profileButton(profile)
                    }
                }
                .padding(.top, 6)

                Button(action: onEditProfiles) {
                    HStack(spacing: 8) {
                        Text(AppStrings.Profile.editProfilesCTA)
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(LiquidGlassBackground(cornerRadius: 14, tone: .dark, isHighlighted: true))
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
            .background(sheetBackground)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            LogoGlowView(size: 64, glowScale: 1.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(AppStrings.Profile.switchProfile)
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(.white)

                Text(AppStrings.Profile.switchProfileSubtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.58))
                    .lineLimit(2)
            }

            Spacer()

            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(width: 34, height: 34)
                        .background(LiquidGlassCircleBackground(tone: .dark))
                }
                .buttonStyle(LiquidButtonPressStyle())
            }
        }
    }

    private func profileButton(_ profile: Profile) -> some View {
        let isSelected = profile.id == selectedProfile?.id

        return Button {
            onSelect(profile)
        } label: {
            VStack(spacing: 9) {
                ProfileAvatarView(
                    imageName: profile.imageName,
                    fallbackGlyph: profile.fallbackGlyph,
                    size: 82
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? Color(hex: "F4B000") : Color.white.opacity(0.08), lineWidth: isSelected ? 3 : 1)
                        .padding(isSelected ? -5 : -2)
                )
                .shadow(color: isSelected ? Color(hex: "F4B000").opacity(0.38) : .clear, radius: 14, x: 0, y: 8)

                Text(profile.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidButtonPressStyle())
    }

    private var sheetBackground: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "33105B"),
                        Color(hex: "160D22"),
                        Color(hex: "2F120D"),
                        Color(hex: "0B0B0C")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.62), radius: 28, x: 0, y: -8)
    }
}

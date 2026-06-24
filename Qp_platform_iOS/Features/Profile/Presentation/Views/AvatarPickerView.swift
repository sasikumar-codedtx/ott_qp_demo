import SwiftUI

struct AvatarPickerView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let metrics = avatarGridMetrics(for: proxy.size.width)
            let columns = Array(
                repeating: GridItem(.fixed(metrics.tileSize), spacing: metrics.spacing),
                count: 3
            )

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: metrics.spacing) {
                        ForEach(viewModel.displayAvatarOptions) { option in
                            Button {
                                viewModel.selectAvatar(option)
                                onContinue()
                            } label: {
                                ProfileAvatarTile(
                                    imageName: option.imageName,
                                    isSelected: option.imageName == viewModel.draft.imageName,
                                    size: metrics.tileSize
                                )
                            }
                            .buttonStyle(LiquidButtonPressStyle())
                        }
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.bottom, 112)
                    .padding(.top, 92)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .routeNavigationOverlay(title: AppStrings.Profile.selectAvatar, onBack: onBack)
        .safeAreaInset(edge: .bottom) {
            Button(action: onContinue) {
                Text(AppStrings.Profile.saveProfile)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "151424"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(LiquidGlassBackground(cornerRadius: UIConstants.CornerRadius.sm, tone: .light, isHighlighted: true))
            }
            .buttonStyle(LiquidButtonPressStyle())
            .padding(.horizontal, UIConstants.Spacing.lg)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(Color.black.opacity(0.96))
        }
    }

    private func avatarGridMetrics(for width: CGFloat) -> AvatarGridMetrics {
        let designWidth: CGFloat = 412
        let designHorizontalPadding: CGFloat = 24
        let designSpacing: CGFloat = 16
        let scale = min(max(width / designWidth, 0.92), 1.12)
        let horizontalPadding = max(UIConstants.Spacing.lg, designHorizontalPadding * scale)
        let spacing = designSpacing * scale
        let availableWidth = max(width - (horizontalPadding * 2) - (spacing * 2), 240)
        let tileSize = min(floor(availableWidth / 3), 120)

        return AvatarGridMetrics(
            horizontalPadding: horizontalPadding,
            spacing: spacing,
            tileSize: tileSize
        )
    }
}

private struct ProfileAvatarTile: View {
    let imageName: String?
    let isSelected: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            ProfileAvatarView(
                imageName: imageName,
                fallbackGlyph: "P",
                size: size
            )

            if isSelected {
                RoundedRectangle(cornerRadius: size / 6.4, style: .continuous)
                    .stroke(Color.white, lineWidth: 2.25)
                    .padding(1)

                Color.black.opacity(0.32)
                    .clipShape(RoundedRectangle(cornerRadius: size / 6.7, style: .continuous))

                Circle()
                    .fill(Color.white)
                    .frame(width: max(size * 0.42, 34), height: max(size * 0.42, 34))
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: max(size * 0.18, 15), weight: .black))
                            .foregroundStyle(Color(hex: "D3147C"))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size / 6.7, style: .continuous))
    }
}

private struct AvatarGridMetrics {
    let horizontalPadding: CGFloat
    let spacing: CGFloat
    let tileSize: CGFloat
}
